class RemoveBackgroundJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(image_id)
    image = Image.find_by(id: image_id)
    return unless image&.image_file&.attached?

    input_path  = Tempfile.new([ "rembg_input", File.extname(image.image_file.filename.to_s) ])
    output_path = Tempfile.new([ "rembg_output", ".png" ])

    begin
      File.binwrite(input_path.path, image.image_file.download)

      system("rembg", "i", input_path.path, output_path.path)

      unless File.exist?(output_path.path) && File.size(output_path.path) > 0
        Rails.logger.error("RemoveBackgroundJob: rembg produced no output for Image##{image_id}")
        return
      end

      image.image_file.attach(
        io: File.binread(output_path.path),
        filename: "nobg_#{image.image_file.filename}",
        content_type: "image/png"
      )
    ensure
      input_path.close(true)
      output_path.close(true)
    end
  end
end
