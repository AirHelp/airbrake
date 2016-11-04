module Airbrake
  module Shoryuken
    ##
    # Provides integration with Shoryuken
    class ErrorHandler
      # rubocop:disable Lint/RescueException
      def call(_worker, _queue, _sqs_msg, body)
        yield
      rescue Exception => exception
        notify_airbrake(exception, body) unless active_job?(context['job_class'])
        raise exception
      end
      # rubocop:enable Lint/RescueException

      private

      def notify_airbrake(exception, context)
        params = context.merge(component: 'shoryuken', action: context['job_class'])
        Airbrake.notify(exception, params)
      end

      def active_job?(class_name)
        activejob_class = "ActiveJob::Base".safe_constantize

        !activejob_class.nil? && class_name.safe_constantize.new.kind_of?(activejob_class)
      end
    end
  end
end

Shoryuken.configure_server do |config|
  config.server_middleware do |chain|
    chain.add(Airbrake::Shoryuken::ErrorHandler)
  end
end
