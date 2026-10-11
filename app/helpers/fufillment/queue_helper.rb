module Fufillment::QueueHelper
  # Display lines for a Hack Club auth address hash. The identity schema
  # isn't documented in-repo, so tolerate string/symbol keys and several
  # common field names; fall back to raw key/value pairs when nothing matches.
  def fulfillment_address_lines(address)
    addr = address.to_h
    fetch = ->(*keys) do
      keys.each do |key|
        value = addr[key] || addr[key.to_s] || addr[key.to_sym]
        return value if value.present?
      end
      nil
    end

    lines = []

    recipient = [
      fetch.call(:first_name, "firstName"),
      fetch.call(:last_name, "lastName")
    ].select(&:present?).join(" ").presence
    recipient ||= fetch.call(:recipient, :name, :full_name, "fullName")
    lines << recipient if recipient.present?

    street = fetch.call(:line1, :line_1, :street, :street_address, :address_line1, "addressLine1")
    lines << street if street.present?

    street2 = fetch.call(:line2, :line_2, :address_line2, "addressLine2")
    lines << street2 if street2.present?

    city_line = [
      fetch.call(:city, :locality, :town),
      fetch.call(:state, :region, :province, :state_code),
      fetch.call(:postal_code, :zip, :zip_code, :postcode, "postalCode", "zipCode")
    ].select(&:present?).join(", ")
    lines << city_line if city_line.present?

    country = fetch.call(:country, :country_code, :country_name)
    lines << country if country.present? && !lines.include?(country)

    if lines.empty?
      addr.each do |key, value|
        next if key.to_s == "id" || value.blank?

        lines << "#{key.to_s.humanize}: #{value}"
      end
    end

    lines.compact_blank
  end
end
