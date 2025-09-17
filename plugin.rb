# name: gipso-themesession-event-creation
# about: Parse participants_group_name from [event] and create group, category, and welcome topic for GiPSo theme sessions
# version: 0.4
# authors: Ludo Vangilbergen

after_initialize do
  Rails.logger.info("📣 Gipso Event Group/Category plugin initialized")

  #
  # Parse parameters inside [event ...] tag
  #
  def parse_event_parameters(raw)
    return {} unless raw =~ /\[event\s+([^\]]+)\]/

    params = {}
    $1.scan(/(\w+)=["']?([^"'\s]+)["']?/).each do |key, value|
      params[key.underscore.to_sym] = value
    end
    params
  rescue => e
    Rails.logger.error("📣 parse_event_parameters error: #{e.class} - #{e.message}")
    {}
  end

  #
  # Store participants_group_name in topic custom fields
  #
  def store_group_name_in_topic(topic, group_name)
    return unless group_name.present?
    return if topic.custom_fields["participants_group_name"] == group_name

    topic.custom_fields["participants_group_name"] = group_name
    topic.save_custom_fields
    Rails.logger.info("📣 Stored participants_group_name='#{group_name}' in topic #{topic.id}")
  rescue => e
    Rails.logger.error("📣 Error storing participants_group_name: #{e.class} - #{e.message}")
  end

  #
  # Create group, category, and welcome topic for an event
  #
  def create_resources_from_event(topic, group_name)
    # === Group ===
    group = Group.find_by(name: group_name)
    if group
      Rails.logger.info("📣 Group already exists: #{group.name}")
    else
      group = Group.create!(
        name: group_name,
        visibility_level: Group.visibility_levels[:public]
      )
      Rails.logger.info("📣 Created new group: #{group.name}")
    end

    # Add event author to group
    if topic.user
      group.add(topic.user)
      Rails.logger.info("📣 Ensured #{topic.user.username} is member of group #{group.name}")
    end

    # === Category ===
    category = Category.find_by(name: group_name)
    if category
      Rails.logger.info("📣 Category already exists: #{category.name}")
    else
      category = Category.create!(
        name: group_name,
        user: topic.user,
        color: SecureRandom.hex(3),
        text_color: "FFFFFF"
      )
      Rails.logger.info("📣 Created new category: #{category.name}")
    end

    # Restrict permissions to the group
    category.set_permissions({ group.name => :full })
    category.save!
    Rails.logger.info("📣 Set/confirmed permissions on #{category.name} for group #{group.name}")


 # === ✨ Nieuw: event-auteur laten observeren ===
  if topic.user
    CategoryUser.find_or_create_by!(
      user: topic.user,
      category: category
    ) do |cu|
      # kies zelf: :watching of :watching_first_post
      cu.notification_level = CategoryUser.notification_levels[:watching]
    end
    Rails.logger.info("📣 #{topic.user.username} set to 'watching' category #{category.name}")
  end


    # === Welcome topic ===
    if category.topics.empty?
      TopicCreator.create!(
        topic.user,
        title: "Welcome to #{category.name}",
        raw: "This is the private space for participants of **#{topic.title}**. 🎉",
        category: category.id
      )
      Rails.logger.info("📣 Created welcome topic in category #{category.name}")
    else
      Rails.logger.info("📣 Category #{category.name} already has topics, skipping welcome topic creation")
    end
  rescue => e
    Rails.logger.error("📣 Calendar Event Resource Creation Error: #{e.class} - #{e.message}")
  end

  #
  # Handle new or edited event posts
  #
  def handle_event_post(post)
    return unless post.post_number == 1
    return unless post.raw.include?("[event")

    params = parse_event_parameters(post.raw)
    if params[:participants_group_name]
      group_name = params[:participants_group_name]
      store_group_name_in_topic(post.topic, group_name)
      create_resources_from_event(post.topic, group_name)
    else
      Rails.logger.debug("📣 No participants_group_name found in post #{post.id}")
    end
  rescue => e
    Rails.logger.error("📣 handle_event_post error for post #{post.id}: #{e.class} - #{e.message}")
  end

  #
  # Hooks
  #
  on(:post_created) do |post, _params|
    handle_event_post(post)
  end

  on(:post_edited) do |post, _params|
    handle_event_post(post)
  end
end

