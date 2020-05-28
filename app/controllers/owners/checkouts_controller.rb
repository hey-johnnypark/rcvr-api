module Owners
  class CheckoutsController < Owners::ApplicationController
    before_action :authenticate_owner!

    def create
      render json: checkout_session
    end

    private

    def checkout_session
      Stripe::Checkout::Session.create(checkout_session_params)
    end

    def checkout_session_params
      params = {
        success_url: "#{ENV['FRONTEND_URL']}/business/profile?success=true",
        cancel_url: "#{ENV['FRONTEND_URL']}/business/profile?success=false",
        payment_method_types: ['card'],
        client_reference_id: current_owner.id,
      }

      if current_owner.stripe_subscription_id?
        params.merge(params_for_existing_subscription)
      else
        params.merge(params_for_new_subscription)
      end
    end

    def params_for_new_subscription
      {
        mode: 'subscription',
        customer_email: current_owner.email,
        line_items: [{ price: ENV['STRIPE_SUBSCRIPTION_PRICE_ID'], quantity: current_owner.companies.count }],
      }
    end

    def params_for_existing_subscription
      {
        mode: 'setup',
        customer: current_owner.stripe_customer_id,
        setup_intent_data: {
          metadata: {
            subscription_id: current_owner.stripe_subscription_id
          }
        }
      }
    end
  end
end
