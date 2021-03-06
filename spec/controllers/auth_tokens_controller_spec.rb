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

require 'spec_helper'

describe AuthTokensController do

  it "should not allow access to admins or owners" do
    sign_in( Factory(:admin) )
    post :create
    response.code.should eql("302")

    sign_in(Factory(:quentin))
    post :create
    response.code.should eql("302")
  end

  it "should bail cleanly on missing auth_token" do
    sign_in(Factory(:token_user))

    post :create

    response.code.should eql("422")
  end

  it "should bail cleanly on missing domains" do
    sign_in(Factory(:token_user))

    post :create, :auth_token => { :domain => 'example.org' }

    response.code.should eql("404")
  end

  it "bail cleanly on invalid requests" do
    Factory(:domain)

    sign_in(Factory(:token_user))

    post :create, :auth_token => { :domain => 'example.com' }

    response.should have_selector('error')
  end

  describe "generating tokens" do

    before(:each) do
      sign_in(Factory(:token_user))

      @domain = Factory(:domain)
      @params = { :domain => @domain.name, :expires_at => 1.hour.since.to_s(:rfc822) }
    end

    it "with allow_new set" do
      post :create, :auth_token => @params.merge(:allow_new => 'true')

      response.should have_selector('token > expires')
      response.should have_selector('token > auth_token')
      response.should have_selector('token > url')

      assigns(:auth_token).should_not be_nil
      assigns(:auth_token).domain.should eql( @domain )
      assigns(:auth_token).should be_allow_new_records
    end

    it "with remove set" do
      a = Factory(:www, :domain => @domain)
      post :create, :auth_token => @params.merge(:remove => 'true', :record => ['www.example.com'])

      response.should have_selector('token > expires')
      response.should have_selector('token > auth_token')
      response.should have_selector('token > url')

      assigns(:auth_token).remove_records?.should be_true
      assigns(:auth_token).can_remove?( a ).should be_true
    end

    it "with policy set" do
      post :create, :auth_token => @params.merge(:policy => 'allow')

      response.should have_selector('token > expires')
      response.should have_selector('token > auth_token')
      response.should have_selector('token > url')

      assigns(:auth_token).policy.should eql(:allow)
    end

    it "with protected records" do
      a = Factory(:a, :domain => @domain)
      www = Factory(:www, :domain => @domain)
      mx = Factory(:mx, :domain => @domain)

      post :create, :auth_token => @params.merge(
        :protect => ['example.com:A', 'www.example.com'],
        :policy => 'allow'
      )

      response.should have_selector('token > expires')
      response.should have_selector('token > auth_token')
      response.should have_selector('token > url')

      assigns(:auth_token).should_not be_nil
      assigns(:auth_token).can_change?( a ).should be_false
      assigns(:auth_token).can_change?( mx ).should be_true
      assigns(:auth_token).can_change?( www ).should be_false
    end

    it "with protected record types" do
      mx = Factory(:mx, :domain => @domain)

      post :create, :auth_token => @params.merge(:policy => 'allow', :protect_type => ['MX'])

      assigns(:auth_token).can_change?( mx ).should be_false
    end

    it "with allowed records" do
      a = Factory(:a, :domain => @domain)
      www = Factory(:www, :domain => @domain)
      mx = Factory(:mx, :domain => @domain)

      post :create, :auth_token => @params.merge(:record => ['example.com'])

      assigns(:auth_token).can_change?( www ).should be_false
      assigns(:auth_token).can_change?( a ).should be_true
      assigns(:auth_token).can_change?( mx ).should be_true
    end

  end
end
