if Rails.env.development?
  task :annotate_models do
    system("bundle exec annotaterb models")
  end

  task "db:migrate" => :annotate_models
end
