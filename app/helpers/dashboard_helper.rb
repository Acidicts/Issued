module DashboardHelper
  def format_threads(amount)
    number_with_delimiter(amount)
  end

  def status_mark(status)
    case status
    when :approved then "✓"
    when :pending then "○"
    when :draft then "✎"
    when :rejected then "✗"
    else "?"
    end
  end

  def status_label(status)
    case status
    when :approved then "approved"
    when :pending then "pending"
    when :draft then "draft"
    when :rejected then "rejected"
    else status.to_s
    end
  end
end
