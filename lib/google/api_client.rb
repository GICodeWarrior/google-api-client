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

require 'google/api_client/version'

module Google #:nodoc:
  ##
  # This class manages communication with a single API.
  class APIClient
    def initialize(options={})
      @options = {
        # TODO: What configuration options need to go here?
      }.merge(options)
      unless @options[:authentication]
        require 'google/api_client/auth/oauth_1'
        # NOTE: Do not rely on this default value, as it may change
        @options[:authentication] = OAuth1.new
      end
      unless @options[:transport]
        require 'google/api_client/transport/http_transport'
        @options[:transport] = HTTPTransport
      end
    end
  end
end
