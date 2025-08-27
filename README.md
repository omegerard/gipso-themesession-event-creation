# gipso-themesession-event-creation

A Discourse plugin that extends the [discourse-calendar](https://meta.discourse.org/t/discourse-calendar/97376) plugin.

## Features
- On creating a new event post, checks for the custom field `participants_group_name`.
- If present:
  - Creates a group with that name.
  - Adds the event author to the group.
  - Creates a category with the same name.
  - Grants the group access to the category.
  - Creates a first “Welcome” post in the new category.

## Installation
Clone into your Discourse `plugins/` directory:

```bash
cd /var/discourse
git clone https://github.com/omegerard/gipso-themesession-event-creation.git plugins/calendar-event-logger

