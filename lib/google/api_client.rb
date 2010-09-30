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

require 'httpadapter'
require 'json'

require 'google/api_client/discovery'

module Google #:nodoc:
  # TODO(bobaman): Document all this stuff.

  ##
  # This class manages communication with a single API.
  class APIClient
    ##
    # An error which is raised when there is an unexpected response or other
    # transport error that prevents an operation from succeeding.
    class TransmissionError < StandardError
    end

    def initialize(options={})
      @options = {
        # TODO: What configuration options need to go here?
      }.merge(options)
      if !self.authorization.respond_to?(:generate_authenticated_request)
        raise TypeError,
          'Expected authorization mechanism to respond to ' +
          '#generate_authenticated_request.'
      end
    end

    ##
    # Returns the parser used by the client.
    def parser
      unless @options[:parser]
        require 'google/api_client/parsers/json_parser'
        # NOTE: Do not rely on this default value, as it may change
        @options[:parser] = JSONParser
      end
      return @options[:parser]
    end

    ##
    # Returns the authorization mechanism used by the client.
    def authorization
      unless @options[:authorization]
        require 'signet/oauth_1/client'
        # NOTE: Do not rely on this default value, as it may change
        @options[:authorization] = Signet::OAuth1::Client.new(
          :temporary_credential_uri =>
            'https://www.google.com/accounts/OAuthGetRequestToken',
          :authorization_uri =>
            'https://www.google.com/accounts/OAuthAuthorizeToken',
          :token_credential_uri =>
            'https://www.google.com/accounts/OAuthGetAccessToken',
          :client_credential_key => 'anonymous',
          :client_credential_secret => 'anonymous'
        )
      end
      return @options[:authorization]
    end

    ##
    # Returns the HTTP adapter used by the client.
    def http_adapter
      return @options[:http_adapter] ||= (begin
        require 'httpadapter/adapters/net_http'
        @options[:http_adapter] = HTTPAdapter::NetHTTPRequestAdapter
      end)
    end

    ##
    # Returns the URI for the discovery document.
    #
    # @return [Addressable::URI] The URI of the discovery document.
    def discovery_uri
      return @options[:discovery_uri] ||= (begin
        if @options[:service]
          service_id = @options[:service]
          service_version = @options[:service_version] || 'v1'
          Addressable::URI.parse(
            "http://www.googleapis.com/discovery/0.1/describe" +
            "?api=#{service_id}"
          )
        else
          raise ArgumentError,
            'Missing required configuration value, :discovery_uri.'
        end
      end)
    end

    def discovery_document
      return @discovery_document ||= (begin
        request = ['GET', self.discovery_uri.to_s, [], []]
        response = self.transmit_request(request)
        status, headers, body = response
        if status == 200 # TODO(bobaman) Better status code handling?
          merged_body = StringIO.new
          body.each do |chunk|
            merged_body.write(chunk)
          end
          merged_body.rewind
          JSON.parse(merged_body.string)
        else
          raise TransmissionError,
            "Could not retrieve discovery document at: #{self.discovery_uri}"
        end
      end)
    end

    def discovered_services
      return @discovered_services ||= (begin
        service_names = self.discovery_document['data'].keys()
        services = []
        for service_name in service_names
          versions = self.discovery_document['data'][service_name]
          for service_version in versions.keys()
            service_description =
              self.discovery_document['data'][service_name][service_version]
            services << ::Google::APIClient::Service.new(
              service_name,
              service_version,
              service_description
            )
          end
        end
        services
      end)
    end

    def discovered_service(service_name, service_version='v1')
      if !service_name.kind_of?(String) && !service_name.kind_of?(Symbol)
        raise TypeError,
          "Expected String or Symbol, got #{service_name.class}."
      end
      service_name = service_name.to_s
      for service in self.discovered_services
        if service.name == service_name &&
            service.version.to_s == service_version.to_s
          return service
        end
      end
      return nil
    end

    def discovered_method(rpc_name, service_version='v1')
      if !rpc_name.kind_of?(String) && !rpc_name.kind_of?(Symbol)
        raise TypeError,
          "Expected String or Symbol, got #{rpc_name.class}."
      end
      rpc_name = rpc_name.to_s
      for service in self.discovered_services
        # This looks kinda weird, but is not a real problem because there's
        # almost always only one service, and this is memoized anyhow.
        if service.version.to_s == service_version.to_s
          return service.to_h[rpc_name] if service.to_h[rpc_name]
        end
      end
      return nil
    end

    def latest_service(service_name)
      if !service_name.kind_of?(String) && !service_name.kind_of?(Symbol)
        raise TypeError,
          "Expected String or Symbol, got #{service_name.class}."
      end
      service_name = service_name.to_s
      versions = {}
      for service in self.discovered_services
        next if service.name != service_name
        sortable_version = service.version.gsub(/^v/, '').split('.').map do |v|
          v.to_i
        end
        versions[sortable_version] = service
      end
      return versions[versions.keys.sort.last]
    end

    def generate_request(
        api_method, parameters={}, body='', headers=[], options={})
      options={
        :signed => true,
        :parser => self.parser,
        :service_version => 'v1'
      }.merge(options)
      if api_method.kind_of?(String) || api_method.kind_of?(Symbol)
        api_method = self.discovered_method(
          api_method.to_s, options[:service_version]
        )
      elsif !api_method.kind_of?(::Google::APIClient::Service)
        raise TypeError,
          "Expected String, Symbol, or Google::APIClient::Service, " +
          "got #{api_method.class}."
      end
      unless api_method
        raise ArgumentError, "API method does not exist."
      end
      request = api_method.generate_request(parameters, body, headers)
      if options[:signed]
        request = self.sign_request(request)
      end
      return request
    end

    def execute(api_method, parameters={}, body='', headers=[], options={})
      request = self.generate_request(
        api_method, parameters, body, headers, options
      )
      return self.transmit_request(request)
    end

    def transmit_request(request, adapter=self.http_adapter)
      ::HTTPAdapter.transmit(request, adapter)
    end

    def sign_request(request)
      return self.authorization.generate_authenticated_request(
        :request => request
      )
    end
  end
end

require 'google/api_client/version'
