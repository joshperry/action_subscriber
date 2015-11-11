module ActionSubscriber
  class Base
    extend ::ActionSubscriber::DefaultRouting
    extend ::ActionSubscriber::DSL
    extend ::ActionSubscriber::Subscribable

    ##
    # Private Attributes
    #
    private

    attr_reader :env, :payload, :raw_payload

    public

    ##
    # Constructor
    #
    def initialize(env)
      @env = env
      @payload = env.payload
      @raw_payload = env.encoded_payload
    end

    ##
    # Class Methods
    #

    def self.connection
      ::ActionSubscriber::RabbitConnection.subscriber_connection
    end

    # Inherited callback, save a reference to our descendents
    #
    def self.inherited(klass)
      super

      inherited_classes << klass
    end

    # Storage for any classes that inherited from us
    #
    def self.inherited_classes
      @_inherited_classes ||= []
    end

    ##
    # Class Aliases
    #
    class << self
      alias_method :subscribers, :inherited_classes
    end

    ##
    # Private Instance Methods
    #
    private

    def acknowledge
      env.acknowledge
    end

    def _at_least_once_filter
      yield
      acknowledge
    rescue => error
      ::ActionSubscriber::MessageRetry.redeliver_message_with_backoff(env)
      acknowledge
      raise error
    end

    def _at_most_once_filter
      acknowledge
      yield
    end

    def reject
      env.reject
    end
  end
end
