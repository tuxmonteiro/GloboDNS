# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# = Start of Authority Record
# Defined in RFC 1035. The SOA defines global parameters for the zone (domain).
# There is only one SOA record allowed in a zone file.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/soa.html

class SOA < Record
  # the portions of the +content+ column that make up our SOA fields
  SOA_FIELDS = %w{primary_ns contact serial refresh retry expire minimum}
  ACCESSIBLE_SOA_FIELDS = SOA_FIELDS - ['serial']

  validates_presence_of      :primary_ns, :content, :serial, :refresh, :retry, :expire, :minimum
  validates_numericality_of  :serial
  validates_bind_time_format :refresh, :retry, :expire, :minimum
  # validates_numericality_of :serial, :refresh, :retry, :expire, :allow_blank => true, :greater_than_or_equal_to => 0
  # validates_numericality_of :minimum, :allow_blank => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 21600 # 10800
  validates_uniqueness_of    :domain_id, :on => :update
  validates                  :contact, :presence => true, :hostname => true
  validates                  :name,    :presence => true, :hostname => true

  # before_validation :update_serial
  before_validation :set_name
  before_validation :set_content
  after_initialize  :update_convenience_accessors

  attr_accessible  :domain_id, :type, :name, :ttl, :prio, :content, *ACCESSIBLE_SOA_FIELDS

  # this allows us to have these convenience attributes act like any other
  # column in terms of validations
  SOA_FIELDS.each do |soa_entry|
    attr_reader soa_entry
    attr_reader soa_entry + '_was'

    define_method "#{soa_entry}_before_type_cast" do
      instance_variable_get("@#{soa_entry}")
    end

    define_method "#{soa_entry}=" do |value|
      instance_variable_set("@#{soa_entry}", value)
      set_content
      instance_variable_get("@#{soa_entry}")
    end
  end

  def initialize(*args)
    super(*args)
    self.serial = 0
  end

  # hook into #reload
  def reload_with_content
    reload_without_content
    update_convenience_accessors
  end
  alias_method_chain :reload, :content

  # def update_serial
  #     update_serial! if self.new_record? || self.changed?
  # end
  #
  # updates the serial number to the next logical one. Format of the generated
  # serial is YYYYMMDDNN, where NN is the number of the change for the day
  def update_serial(save = false)
    domains = nil
    view_default = self.domain.view == Domain::DEFAULT_VIEW
    enabled_view = (defined? GloboDns::Config::ENABLE_VIEW) && GloboDns::Config::ENABLE_VIEW

    original_serial = self.serial
    if enabled_view
      domains = Domain.where("name = :name and view_id != :view_id",  { name: self.domain.name, view_id: self.domain.view_id })
      domains.each do |d|
        soa = d.records.where(type: "SOA").first
        serial = soa.serial
        self.serial = serial if serial > self.serial && (view_default || soa.domain.view == Domain::DEFAULT_VIEW)
      end
    end

    if original_serial == self.serial
      current_date = Time.now.strftime('%Y%m%d')
      if self.serial/100 >= current_date.to_i
        self.serial += 1
      else
        self.serial = (current_date + '00').to_i
      end
    end

    if enabled_view && domains != nil && save
      domains.each do |d|
        soa = d.records.where(type: "SOA").first
        soa.serial = self.serial
        soa.set_content
        self.transaction do
          soa.update_column(:content, soa.content)
        end
      end
    end

    if save
      set_content
      self.transaction do
        self.update_column(:content, self.content)
      end
    end
  end

  def set_content
    self.content = SOA_FIELDS.map { |f| instance_variable_get("@#{f}").to_s  }.join(' ')
  end

  def set_name
    self.name ||= '@'
  end

  def resolv_resource_class
    Resolv::DNS::Resource::IN::SOA
  end

  def to_partial_path
    "#{self.class.superclass.name.underscore.pluralize}/soa_record"
  end

  def match_resolv_resource(resource)
    resource.mname.to_s == self.primary_ns.chomp('.')  &&
      resource.rname.to_s == self.contact.chomp('.') &&
      resource.serial     == self.serial             &&
      resource.refresh    == self.refresh            &&
      resource.retry      == self.retry              &&
      resource.expire     == self.expire             &&
      resource.minimum    == self.minimum
  end

  private

  # update our convenience accessors when the object has changed
  def update_convenience_accessors
    return if self.content.blank? || ACCESSIBLE_SOA_FIELDS.select{ |field| send(field).blank? }.empty?

    soa_fields = self.content.split(/\s+/)
    raise Exception.new("Invalid SOA Record content attribute: #{self.content}") unless soa_fields.size == SOA_FIELDS.size

    soa_fields.each_with_index do |field_value, index|
      field_name  = SOA_FIELDS[index]
      field_value = field_value.try(:to_i) if field_name == 'serial'
      instance_variable_set("@#{field_name}", field_value)
      instance_variable_set("@#{field_name}_was", field_value)
    end
    # update_serial if @serial.nil? || @serial.zero?
  end
end
