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

## Attention

The value for participants_group_name is not saved when you create an event (bug in discourse?). You need to edit the event and fill in the participants_group_name custom field.

## Installation
Clone into your Discourse `plugins/` directory:

```bash
cd /var/discourse
git clone https://github.com/omegerard/gipso-themesession-event-creation.git plugins/calendar-event-logger

