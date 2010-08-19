# Copyright 2010 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

require 'google/api_client'
require 'google/api_client/version'
require 'google/api_client/parser/json_parser'
require 'google/api_client/auth/oauth_1'
require 'google/api_client/transport/http_transport'


describe Google::APIClient, 'with default configuration' do
  before do
    @client = Google::APIClient.new
  end

  it 'should make its version number available' do
    ::Google::APIClient::VERSION::STRING.should be_instance_of(String)
  end

  it 'should use the default JSON parser' do
    @client.parser.should be_instance_of(Google::APIClient::JSONParser)
  end
end

describe Google::APIClient, 'with custom pluggable parser' do
  before do
    class FakeJsonParser
    end

    @client = Google::APIClient.new(:parser => FakeJsonParser.new)
  end

  it 'should use the custom parser' do
    @client.parser.should be_instance_of(FakeJsonParser)
  end
end
