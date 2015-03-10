class PaymentGatewayCustomer
  pattr_initialize :user

  def email
    customer.email
  end

  def card_last4
    default_card.last4
  end

  def customer
    @customer ||= begin
      if user.stripe_customer_id.present?
        Stripe::Customer.retrieve(user.stripe_customer_id)
      else
        NoRecord.new
      end
    end
  end

  def subscriptions
    customer.subscriptions.data
  end

  def update_card(card_token)
    customer.card = card_token
    customer.save
  end

  def update_email(email)
    customer.email = email
    customer.save
  rescue Stripe::APIError => e
    Raven.capture_exception(e)
    false
  end

  private

  def default_card
    customer.cards.detect { |card| card.id == customer.default_card } ||
      BlankCard.new
  end

  class NoRecord
    def email
      ""
    end

    def cards
      []
    end

    def subscriptions
      NoSubscription.new
    end
  end

  class NoSubscription
    def retrieve(*_args)
      nil
    end

    def data
      []
    end
  end

  class BlankCard
    def last4
      ""
    end
  end

  class NoDiscount
    def coupon
      NoCoupon.new
    end
  end

  class NoCoupon
    def amount_off
      0
    end

    def percent_off
      0
    end

    def valid
      true
    end
  end
end
