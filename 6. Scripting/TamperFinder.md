
```sh
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage1: $0 <URL>"
    exit 1
fi

URL=$1

ENDPOINTS=("archives" "booking_date" "calendars" "categories" "configuration_types" "configurations" "contact_types" "contacts" "cookie_configurations" "email_admins" "environments" "event_categories" "events" "excel_exporters" "features" "file_favorites" "file_types" "files" "firebase_tokens" "incidence_categories" "incidences" "issue_queues" "issue_special_services" "issues" "languages" "lost_objects" "memories" "metro_menu_items" "metro_menus" "news" "newsletters" "no_technique_visit_courses" "no_technique_visit_group_types" "no_technique_visit_course_types" "no_technique_visits" "notification_histories" "optimizers" "panelists" "point_of_interests" "polls" "press_releases" "professional_contacts" "professional_media" "queues" "rates" "reembolso_anuals" "station_exits" "stations" "tags" "technique_visits" "tickets" "user_favorite_stations" "user_media" "user_routes" "users" "visit_details" "visits" "week_trip_Frequencies" "zones")

for end in ${ENDPOINTS[@]};
do
    FULL="${URL}${end}?page=1&perPage=2"
    for metodo in GET POST OPTIONS HEAD PUT DELETE TRACE PATCH;
    do
        RESPONSE=$(curl -kis -X ${metodo} "${FULL}" -H "accept: application/ld+json" | head -n 1 | awk '{print $2}')
        if [[ ${RESPONSE} == 200 ]]; then
            printf "${end} -> ${metodo} -> ${FULL} \n"
        fi
    done
done
```