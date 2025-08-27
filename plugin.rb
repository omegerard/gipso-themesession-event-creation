# name: gipso-themesession-event-creation
# about: Extends calendar-event plugin with group/category creation for Gipso theme session events
# version: 0.3
# authors: Ludo Vangilbergen

after_initialize do
  Rails.logger.warn("📣 Calendar Event Logger plugin initialized")

  #
  # Parse event parameters from the raw [event ...] tag in a post
  #
  def parse_event_parameters(raw)
    return {} unless raw =~ /\[event(.+?)\]/

    params = {}
    $1.scan(/(\w+)=["'](.+?)["']/).each do |key, value|
      params[key.underscore.to_sym] = value
    end
    params
  end

  #
  # Hook: after a post is created
  #
  on(:post_created) do |post|
    next unless post.post_number == 1 # Only process first posts (topic OP)

    event_params = parse_event_parameters(post.raw)
    group_name = event_params[:participants_group_name]

    if group_name.present?
      Rails.logger.warn("📣 EVENT parameters found for Topic #{post.topic_id}")
      Rails.logger.warn("📣 participants_group_name = #{group_name}")

      if post.topic
        post.topic.custom_fields['participants_group_name'] = group_name
        post.topic.save_custom_fields
        Rails.logger.warn("📣 Stored participants_group_name in topic custom fields")

        create_resources_from_event(post.topic, group_name)
      end
    end
  rescue => e
    Rails.logger.error("📣 Calendar Event Logger Error: #{e.message}\n#{e.backtrace.join("\n")}")
  end

  #
  # Create group, category, and welcome topic for an event
  #
  def create_resources_from_event(topic, group_name)
    group = Group.find_by(name: group_name) || Group.create!(
      name: group_name,
      visibility_level: Group.visibility_levels[:public]
    )
    Rails.logger.warn("📣 Created/updated group: #{group.name}")

    # Add event author to group
    if topic.user
      group.add(topic.user)
      Rails.logger.warn("📣 Added #{topic.user.username} to group #{group.name}")
    end

    # Create or find category with the same name
    category = Category.find_by(name: group_name) || Category.create!(
      name: group_name,
      user: topic.user,
      color: SecureRandom.hex(3),
      text_color: 'FFFFFF'
    )
    Rails.logger.warn("📣 Created/updated category: #{category.name}")

    # Restrict permissions to the group
    category.set_permissions({ group.name => :full })
    category.save!
    Rails.logger.warn("📣 Set permissions on #{category.name} for group #{group.name}")

    # Create welcome topic if empty
    if category.topics.empty?
      TopicCreator.create!(
        topic.user,
        title: "Welcome to #{category.name}",
        raw: "This is the private space for participants of **#{topic.title}**. 🎉",
        category: category.id
      )
      Rails.logger.warn("📣 Created welcome topic in category #{category.name}")
    end
  rescue => e
    Rails.logger.error("📣 Calendar Event Resource Creation Error: #{e.message}\n#{e.backtrace.join("\n")}")
  end
end

