//
// Copyright 2022-2023 by garmin@ibuyonline.nl
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and 
// associated documentation files (the "Software"), to deal in the Software without restriction, 
// including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or 
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Toybox.Communications;
import Toybox.Lang;

var _communicationsError = {
    Communications.UNKNOWN_ERROR                                    => "An unknown error has occurred.",
    Communications.BLE_ERROR                                        => "A generic bluetooth error has occurred.",
    Communications.BLE_HOST_TIMEOUT                                 => "We timed out waiting for a response from the host.",
    Communications.BLE_SERVER_TIMEOUT                               => "We timed out waiting for a response from a server.",
    Communications.BLE_NO_DATA                                      => "Response contained no data.",
    Communications.BLE_REQUEST_CANCELLED                            => "The request was cancelled at the request of the system.",
    Communications.BLE_QUEUE_FULL                                   => "Too many requests have been made.",
    Communications.BLE_REQUEST_TOO_LARGE                            => "Serialized input data for the request was too large.",
    Communications.BLE_UNKNOWN_SEND_ERROR                           => "Send failed for an unknown reason.",
    Communications.BLE_CONNECTION_UNAVAILABLE                       => "No bluetooth connection is available.",
    Communications.INVALID_HTTP_HEADER_FIELDS_IN_REQUEST            => "Request contained invalid http header fields.",
    Communications.INVALID_HTTP_BODY_IN_REQUEST                     => "Request contained an invalid http body.",
    Communications.INVALID_HTTP_METHOD_IN_REQUEST                   => "Request used an invalid http method.",
    Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE            => "Response body data is invalid for the request type.",
    Communications.INVALID_HTTP_HEADER_FIELDS_IN_NETWORK_RESPONSE   => "Response contained invalid http header fields.",
    Communications.NETWORK_RESPONSE_TOO_LARGE                       => "Serialized response was too large.",
    Communications.NETWORK_RESPONSE_OUT_OF_MEMORY                   => "Ran out of memory processing network response.",
    Communications.STORAGE_FULL                                     => "Filesystem too full to store response data.",
    Communications.SECURE_CONNECTION_REQUIRED                       => "Indicates an https connection is required for the request.",
    Communications.UNSUPPORTED_CONTENT_TYPE_IN_RESPONSE             => "Content type given in response is not supported or does not match what is expected.",
    Communications.REQUEST_CANCELLED                                => "Http request was cancelled by the system.",
    Communications.REQUEST_CONNECTION_DROPPED                       => "Connection was lost before a response could be obtained.",
    Communications.UNABLE_TO_PROCESS_MEDIA                          => "Downloaded media file was unable to be read.",
    Communications.UNABLE_TO_PROCESS_IMAGE                          => "Downloaded image file was unable to be processed.",
    Communications.UNABLE_TO_PROCESS_HLS                            => "HLS content could not be downloaded. Most often occurs when requested and provided bit rates do not match."
};

(:background)
class CommunicationsError {
    public function Message( errorCode as Number ) as String {
        return _communicationsError.get(errorCode);
    }
}