# frozen_string_literal: true

module Esse
  class Error < StandardError
  end

  # @todo Rename this
  module Transport
    class ServerError < ::Esse::Error; end

    ES_TRANSPORT_ERRORS = {
      'MultipleChoices' => 'MultipleChoicesError', # 300
      'MovedPermanently' => 'MovedPermanentlyError', # 301
      'Found' => 'FoundError', # 302
      'SeeOther' => 'SeeOtherError', # 303
      'NotModified' => 'NotModifiedError', # 304
      'UseProxy' => 'UseProxyError', # 305
      'TemporaryRedirect' => 'TemporaryRedirectError', # 307
      'PermanentRedirect' => 'PermanentRedirectError', # 308
      'BadRequest' => 'BadRequestError', # 400
      'Unauthorized' => 'UnauthorizedError', # 401
      'PaymentRequired' => 'PaymentRequiredError', # 402
      'Forbidden' => 'ForbiddenError', # 403
      'NotFound' => 'NotFoundError', # 404
      'MethodNotAllowed' => 'MethodNotAllowedError', # 405
      'NotAcceptable' => 'NotAcceptableError', # 406
      'ProxyAuthenticationRequired' => 'ProxyAuthenticationRequiredError', # 407
      'RequestTimeout' => 'RequestTimeoutError', # 408
      'Conflict' => 'ConflictError', # 409
      'Gone' => 'GoneError', # 410
      'LengthRequired' => 'LengthRequiredError', # 411
      'PreconditionFailed' => 'PreconditionFailedError', # 412
      'RequestEntityTooLarge' => 'RequestEntityTooLargeError', # 413
      'RequestURITooLong' => 'RequestURITooLongError', # 414
      'UnsupportedMediaType' => 'UnsupportedMediaTypeError', # 415
      'RequestedRangeNotSatisfiable' => 'RequestedRangeNotSatisfiableError', # 416
      'ExpectationFailed' => 'ExpectationFailedError', # 417
      'ImATeapot' => 'ImATeapotError', # 418
      'TooManyConnectionsFromThisIP' => 'TooManyConnectionsFromThisIPError', # 421
      'UpgradeRequired' => 'UpgradeRequiredError', # 426
      'BlockedByWindowsParentalControls' => 'BlockedByWindowsParentalControlsError', # 450
      'RequestHeaderTooLarge' => 'RequestHeaderTooLargeError', # 494
      'HTTPToHTTPS' => 'HTTPToHTTPSError', # 497
      'ClientClosedRequest' => 'ClientClosedRequestError', # 499
      'InternalServerError' => 'InternalServerError', # 500
      'NotImplemented' => 'NotImplementedError', # 501
      'BadGateway' => 'BadGatewayError', # 502
      'ServiceUnavailable' => 'ServiceUnavailableError', # 503
      'GatewayTimeout' => 'GatewayTimeoutError', # 504
      'HTTPVersionNotSupported' => 'HTTPVersionNotSupportedError', # 505
      'VariantAlsoNegotiates' => 'VariantAlsoNegotiatesError', # 506
      'NotExtended' => 'NotExtendedError', # 510
    }

    ERRORS = ES_TRANSPORT_ERRORS.each_with_object({}) do |(transport_name, esse_name), memo|
      memo[transport_name] = const_set esse_name, Class.new(ServerError)
    end
  end

  module Events
    class UnregisteredEventError < ::Esse::Error
      def initialize(object_or_event_id)
        case object_or_event_id
        when String, Symbol
          super("You are trying to publish an unregistered event: `#{object_or_event_id}`")
        else
          super('You are trying to publish an unregistered event')
        end
      end
    end

    class InvalidSubscriberError < ::Esse::Error
      # @api private
      def initialize(object_or_event_id)
        case object_or_event_id
        when String, Symbol
          super("you are trying to subscribe to an event: `#{object_or_event_id}` that has not been registered")
        else
          super('you try use subscriber object that will never be executed')
        end
      end
    end
  end

  module CLI
    class Error < ::Esse::Error
      def initialize(msg = nil, **message_attributes)
        if message_attributes.any?
          msg = format(msg, **message_attributes)
        end
        super(msg)
      end
    end

    class InvalidOption < Error
    end
  end
end
