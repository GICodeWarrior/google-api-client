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


module Google
  class APIClient
    ##
    # An error which is raised when there is an unexpected response or other
    # transport error that prevents an operation from succeeding.
    class TransmissionError < StandardError
    end

    ##
    # An exception that is raised if a method is called with missing or
    # invalid parameter values.
    class ValidationError < StandardError
    end
  end
end
