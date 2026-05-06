module ApplicationHelper
  def flash_bootstrap_class(type)
    { "notice" => "success", "alert" => "danger", "info" => "info", "warning" => "warning" }
      .fetch(type.to_s, "secondary")
  end

  def time_of_day_greeting
    hour = Time.current.hour
    if hour < 12 then "morning"
    elsif hour < 17 then "afternoon"
    else "evening"
    end
  end
end
