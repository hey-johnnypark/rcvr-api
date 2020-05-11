class Ticket < ApplicationRecord
  include ApiSerializable

  belongs_to :area
  has_one :company, through: :area

  validates :id, absence: true, on: :update, if: :id_changed? # Can never update id

  enum status: { neutral: 0, at_risk: 2 }

  EXPOSED_ATTRIBUTES = %i[id entered_at left_at area_id company_name]

  def self.overlapping_time(time_range)
    # Three possibilities: They entered while the other person was there
    # .or they left while the other person was there
    # .or they arrived before and left after (they were there the entire time)
    Ticket.where(entered_at: time_range)
          .or(Ticket.where(left_at: time_range))
          .or(Ticket.where('entered_at <= ? AND left_at >= ?', time_range.begin, time_range.end))
  end

  def self.mark_cases!(time_range, area_id)
    Ticket.transaction do
      Ticket
        .overlapping_time(time_range)
        .where(area_id: area_id)
        .find_each { |ticket| ticket.update(status: :at_risk) }
    end
  end

  def company_name
    company.name
  end
end
