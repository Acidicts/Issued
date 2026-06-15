require "csv"

class Admin::RsvpController < Admin::DashboardController
  def index
    @rsvps = Rsvp.all
  end

  def import
    csv_file = params[:csv_file]

    unless csv_file.present?
      redirect_to admin_rsvp_path, alert: "Please choose a CSV file to import."
      return
    end

    result = import_rsvps_from_csv(csv_file)

    message = "Imported #{result[:imported]} RSVPs"
    message += " and created #{result[:users_created]} users" if result[:users_created].positive?
    message += "."

    if result[:skipped].positive?
      message += " Skipped #{result[:skipped]} row#{'s' unless result[:skipped] == 1}."
    end

    if result[:errors].any?
      flash[:alert] = result[:errors].first(5).join(" ")
    end

    redirect_to admin_rsvp_path, notice: message
  rescue CSV::MalformedCSVError => e
    redirect_to admin_rsvp_path, alert: "Invalid CSV format: #{e.message}"
  rescue ArgumentError => e
    redirect_to admin_rsvp_path, alert: e.message
  end

  def delete
    Rsvp.find(params[:id]).destroy
    redirect_to admin_rsvp_path
  end

  private

  def import_rsvps_from_csv(csv_file)
    imported = 0
    skipped = 0
    users_created = 0
    errors = []

    csv = CSV.parse(read_csv_as_utf8(csv_file), headers: true)
    if csv.headers.blank?
      raise ArgumentError, "The CSV must include headers."
    end

    normalized_headers = csv.headers.compact.map { |header| normalize_header(header) }
    unless normalized_headers.include?("slack_id")
      raise ArgumentError, "CSV must include a 'slack_id' column."
    end

    csv.each_with_index do |row, index|
      row_number = index + 2
      attrs = normalize_row(row)

      slack_id = attrs["slack_id"].presence
      name = attrs["name"].presence

      if slack_id.blank?
        skipped += 1
        errors << "Row #{row_number}: missing slack_id."
        next
      end

      user = User.find_or_initialize_by(slack_id: slack_id)
      users_created += 1 if user.new_record?

      user.name = name if name.present?
      user.ysws_eligible = false if user.ysws_eligible.nil?

      unless user.save
        skipped += 1
        errors << "Row #{row_number}: #{user.errors.full_messages.to_sentence}."
        users_created -= 1 if user.id.nil?
        next
      end

      rsvp = Rsvp.find_or_create_by(user: user)
      imported += 1 if rsvp.previously_new_record?
    end

    {
      imported: imported,
      skipped: skipped,
      users_created: users_created,
      errors: errors
    }
  end

  def normalize_row(row)
    row.to_h.transform_keys { |header| normalize_header(header) }
         .transform_values { |value| normalize_text_value(value) }
  end

  def normalize_header(header)
    header.to_s.strip.downcase.gsub(/\s+/, "_")
  end

  def normalize_text_value(value)
    value.to_s
         .encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "")
         .strip
  end

  def read_csv_as_utf8(csv_file)
    raw = csv_file.read.to_s
    return "" if raw.empty?

    # Try common CSV encodings and normalize all content to UTF-8 for DB safety.
    [ Encoding::UTF_8, Encoding::Windows_1252, Encoding::ISO_8859_1 ].each do |encoding|
      text = raw.dup.force_encoding(encoding)
      next unless text.valid_encoding?

      return text.encode(Encoding::UTF_8).sub(/\A\uFEFF/, "")
    rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
      next
    end

    raw.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "").sub(/\A\uFEFF/, "")
  end
end
