// Entry point for the build script in your package.json

// load Bootstrap 5
// turbo link is disabled because it mess up with authentication links
// import "@hotwired/turbo-rails";


import "./controllers";
import * as bootstrap from "bootstrap";

// load jQuery
import jquery from 'jquery';
window.jQuery = jquery;
window.$ = jquery;

// load datatables
import dt from 'datatables.net-bs5';
window.$.DataTable = dt;

// load moment
import moment from "moment";

// load rails ujs
import Rails from '@rails/ujs';
Rails.start();

// configure constants
const DEBUG = window.location.hostname === '0.0.0.0';
const API_URI = "https://api.open511.gov.bc.ca";
const EVENT_SEARCH_PATH = "/events";
const AREA_PATH = "/areas";
const UPDATE_USAGE_DATA_TIME = 5000; // update usage data every 5 secs

const NA = '<i class="text-muted">N/A</i>';


/*
 * Code begins here:
 * Please note normally I will split a js file like this to a few smaller files.
 * But for easy-to-read reason all functions are defined in one js file.
 */

/// page variables
var currentUserID = $('body').data("user-id"); // the current user's id, null if user not logged in
var eventsTable = undefined; // the main events table (the first table)
var bookmarkedEventsTable = undefined; // the saved events table (the second table)

/// main JS entry of the one-page web ///
$(document).ready(function () {

  configureEventsTable();

  if(currentUserID){
    configureBookmarkedEventsTable();

    configureUsageTable();
  }

});

/// instance functions
// convert a UTC time to local time in a human readable format
const formatTime = (str) => {
  if(str != undefined){
    let times = str.split("/");
    let from = moment.utc(times[0]).local().format('YYYY-MM-DD HH:mm');
    let to = times[1] != undefined && times[1].length > 0 ? moment.utc(times[1]).local().format('YYYY-MM-DD HH:mm') : undefined;
    if(to != undefined){
      return `${from} <i class="text-muted">to</i> ${to}`;
    }
    else{
      return `<i class="text-muted">starting from</i> ${from}`
    }
  }
  else{
    return NA;
  }
};

// configure the main event table (the first table)
const configureEventsTable = () => {
  eventsTable = $('#eventsTable').DataTable({
    columns: [
      {
        className: 'dt-control',
        orderable: false,
        data: null,
        defaultContent: '',
      },
      { data: 'id',
        defaultContent: "<em class='text-muted'>blank</em>",
        className: "text-center",
        orderable: false
      },
      { data: 'headline',
        defaultContent: "<em class='text-muted'>blank</em>",
        className: "text-left",
        orderable: false
      },
      { data: 'eventType',
        defaultContent: "<em class='text-muted'>blank</em>",
        className: "text-right",
        orderable: false
      },
      { data: 'areas',
        defaultContent: "<em class='text-muted'>blank</em>",
        className: "text-right",
        orderable: false
      },
      { data: 'severity',
        defaultContent: "<em class='text-muted'>blank</em>",
        className: "text-right",
        orderable: false
      },
      { data: 'startDate',
        defaultContent: "<em class='text-muted'>blank</em>",
        className: "text-right",
        orderable: false
      },
      {
        data: 'actions',
        className: "text-center",
        orderable: false
      }
    ],
    dom: "rt<'d-flex justify-content-between'lp>",
    ordering: false,
    processing: true,
    serverSide: true,
    ajax: function (data, callback, settings) {
      DEBUG && console.log("data:", data);
      DEBUG && console.log("settings:", settings);

      // pagination options
      let offset = data["start"] || 0;
      let limit = data["length"] || 10;

      // dt options
      let draw = data["draw"];

      // search options
      let url = `${API_URI}${EVENT_SEARCH_PATH}?limit=${limit}&offset=${offset}`;
      if($("#areaFilter").val()){
        url += `&area_id=${encodeURIComponent($("#areaFilter").val())}`;
      }
      if($("#eventTypeFilter").val()){
        url += `&event_type=${encodeURIComponent($("#eventTypeFilter").val())}`;
      }
      if($("#severityFilter").val()){
        url += `&severity=${encodeURIComponent($("#severityFilter").val())}`;
      }
      if($("#startDateFilter").val()){
        url += `&in_effect_on=${$("#startDateFilter").val()}T00:00`;
      }

      DEBUG && console.log("Search URL = ", url);
      $.ajax({
        url: url,
        success: (data) => {

          let events = data["events"];

          DEBUG && console.log("Search returns ", events.length , " records...");
          DEBUG && console.log("Pagination data:", data["pagination"]);

          let recordsFiltered = undefined;
          if(events.length < limit){
            recordsFiltered = offset + events.length;
          }

          // get
          $.ajax({
            url: "/bookmarks/check",
            method: "post",
            data: JSON.stringify({event_ids: events.map((event)=>{return event["id"];})}),
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': $('meta[name=csrf-token]').attr('content'),
            },
            success: (bookmarks) => {
              DEBUG && console.log("checked ids", bookmarks);
              let json = events.map((event)=>{
                let button = '<a href="/sign_in" class="btn btn-outline-primary btn-xs">Log in to save</a>';
                if(currentUserID){
                  if(bookmarks[event["id"]]){
                    button = `<a data-id="btn_${event["id"]}" href="/bookmarks/${bookmarks[event["id"]]}" data-method="delete" data-remote="true" class="btn btn-danger btn-xs">Remove</a>`;
                  }
                  else{
                    button = `<a data-id="btn_${event["id"]}" href="/bookmarks?event_id=${encodeURIComponent(event["id"])}" data-method="post" data-remote="true" class="btn btn-success btn-xs">Save</a>`
                  }
                }
                return {
                  // basic information for the main table
                  DT_RowId: event["id"],
                  id: event["id"] != undefined ? event["id"].split("/")[1] : NA,
                  headline: event["headline"],
                  eventType: event["event_type"],
                  areas: event["areas"].map((area)=>{
                    return area["name"];
                  }).join(", "),
                  severity: event["severity"],
                  startDate: event["schedule"] != undefined && event["schedule"]["intervals"] != undefined ? event["schedule"]["intervals"].map((str)=>{
                    return formatTime(str);
                  }).join("<br>") : NA,
                  actions: button,
                  // additional detail information for the nested table
                  url: event["url"],
                  jurisdictionUrl: event["jurisdiction_url"],
                  description: event["description"],
                  status: event["status"],
                  ivrMessage: event["ivr_message"],
                  eventSubtypes: event["event_subtypes"] != undefined ? event["event_subtypes"].join(", ") : NA,
                  geography: JSON.stringify(event["geography"]),
                  roads: event["roads"].map((road)=>{
                    return `${road["name"]} (from ${road["from"]} to ${road["to"]}) ${road["state"]} (${road["direction"]} direction), +delay: ${road["+delay"] ? road["+delay"] : NA}`;
                  }).join(", "),
                  updated: moment.utc(event["updated"]).local().format('on YYYY-MM-DD at HH:mm:ss'),
                  created: moment.utc(event["created"]).local().format('on YYYY-MM-DD at HH:mm:ss'),
                };
              });
              callback({
                draw: draw || 1,
                recordsTotal: undefined,
                recordsFiltered: recordsFiltered,
                data: json,
              });
            }
          });


        },
        error: (jqXHR, textStatus, errorThrown ) => {
          DEBUG && console.log("ajax call failed...", textStatus);
        }
      });
    },
    searching: false,

    language: {
      processing:     "Loading events...",
      search:         "Search:",
      lengthMenu:     "Show _MENU_ events per page",
      info:           "",
      infoEmpty:      "",
      infoFiltered:   "",
      infoPostFix:    "",
      loadingRecords: "Loading...",
      zeroRecords:    "No matched event found",
      emptyTable:     "No event available in table",
      paginate: {
        first:      "First",
        previous:   "Previous",
        next:       "Next",
        last:       "Last"
      }
    }
  });

  // Add event listener for opening and closing an event row
  $('#eventsTable tbody').on('click', 'td.dt-control', (event) => {
    let tr = $(event.target).closest('tr');
    let row = eventsTable.row(tr);

    if (row.child.isShown()) {
      // this event is already open - close
      row.child.hide();
      tr.removeClass('shown');
    } else {
      row.child(showEventDetails(row.data())).show();
      tr.addClass('shown');
    }
  });

  // configure filter options
  // load and configure areas
  loadAreaOptions();
  // configure event types
  $("#eventTypeFilter").on("change", ()=>{
    eventsTable && eventsTable.ajax.reload();
  });
  // configure severities
  $("#severityFilter").on("change", ()=>{
    eventsTable && eventsTable.ajax.reload();
  });
  // configure start date
  $("#startDateFilter").on("change", ()=>{
    eventsTable && eventsTable.ajax.reload();
  });
};

// display the nested event table
const showEventDetails = (event) => {
  return (`
    <table class="table table-borderless table-sm table-nested">
      <tbody>
        <tr>
          <th>Official ID:</th>
          <td>${event.id}</td>
        </tr>
        <tr>
          <th>Data URL:</th>
          <td>
            <a href="${API_URI}${event.url}" target="_blank">${API_URI}${event.url} <i class="bi bi-hand-index-thumb"></i></a>
          </td>
        </tr>
        <tr>
          <th>Jurisdiction URL:</th>
          <td>
            <a href="${API_URI}${event.jurisdictionUrl}" target="_blank">${API_URI}${event.jurisdictionUrl} <i class="bi bi-hand-index-thumb"></i></a>
          </td>
        </tr>
        <tr>
          <th>Headline:</th>
          <td>${event.headline ? event.headline : NA}</td>
        </tr>
        <tr>
          <th>Status:</th>
          <td>${event.status}</td>
        </tr>
        <tr>
          <th>Severity:</th>
          <td>${event.severity}</td>
        </tr>
        <tr>
          <th>Description:</th>
          <td>${event.description ? event.description : NA}</td>
        </tr>
        <tr>
          <th>Plus IVR Message:</th>
          <td>${event.ivr_message ? event.ivr_message : NA}</td>
        </tr>
        <tr>
          <th>Schedules:</th>
          <td>${event.startDate}</td>
        </tr>
        <tr>
          <th>Event Type:</th>
          <td>${event.eventType}</td>
        </tr>
        <tr>
          <th>Event Subtypes:</th>
          <td>${event.eventSubtypes ? event.eventSubtypes : NA}</td>
        </tr>

        <tr>
          <th>Areas:</th>
          <td>${event.areas}</td>
        </tr>
        <tr>
          <th>Roads:</th>
          <td>${event.roads ? event.roads : NA}</td>
        </tr>
        <tr>
          <th>Geography:</th>
          <td>${event.geography ? event.geography : NA}</td>
        </tr>

        <tr>
          <th>Updated:</th>
          <td>${event.updated}</td>
        </tr>
        <tr>
          <th>Created:</th>
          <td>${event.created}</td>
        </tr>
      </tbody>
    </table>
    `);
};

// load area names and ids from remote API (for area filter)
const loadAreaOptions = () => {
  $("#areaFilter .placeholder").text("Loading options...");
  $.ajax({
    url: `${API_URI}${AREA_PATH}`,
    success: (data) => {
      let areas = data["areas"].map((area)=>{
        $("#areaFilter").append(
          $('<option>', {value: area["id"], text: area["name"]})
        );
      });
      $("#areaFilter .placeholder").text("Unselected");
      $('#areaFilter').removeAttr('disabled');

      $("#areaFilter").on("change", ()=>{
        eventsTable && eventsTable.ajax.reload();
      });
    },
    error: (jqXHR, textStatus, errorThrown ) => {
      $("#areaFilter .placeholder").text("Failed to load options");
    }
  });
};

// configure the saved event table (the second table)
const configureBookmarkedEventsTable = () => {
  bookmarkedEventsTable = $('#bookmarkedEventsTable').DataTable({
    columns: [
      {
        className: 'dt-control',
        orderable: false,
        data: null,
        defaultContent: '',
      },
      { data: 'id',
        defaultContent: "<em class='text-muted'>blank</em>",
        className: "text-center",
        orderable: true
      },
      { data: 'headline',
        defaultContent: "<em class='text-muted'>blank</em>",
        className: "text-left",
        orderable: true
      },
      { data: 'eventType',
        defaultContent: "<em class='text-muted'>blank</em>",
        className: "text-right",
        orderable: true
      },
      { data: 'areas',
        defaultContent: "<em class='text-muted'>blank</em>",
        className: "text-right",
        orderable: false
      },
      { data: 'severity',
        defaultContent: "<em class='text-muted'>blank</em>",
        className: "text-right",
        orderable: true
      },
      { data: 'startDate',
        defaultContent: "<em class='text-muted'>blank</em>",
        className: "text-right",
        orderable: false
      },
      {
        data: 'actions',
        className: "text-center",
        orderable: false
      }
    ],

    ajax: "/bookmarks"
  });

  // Add event listener for opening and closing an event row
  $('#bookmarkedEventsTable tbody').on('click', 'td.dt-control', (event) => {
    let tr = $(event.target).closest('tr');
    let row = bookmarkedEventsTable.row(tr);

    if (row.child.isShown()) {
      // this event is already open - close
      row.child.hide();
      tr.removeClass('shown');
    } else {
      console.log(row.data());
      row.child(showEventDetails(row.data())).show();
      tr.addClass('shown');
    }
  });

  window.reloadBookmarkedEventsTable = () => {
    bookmarkedEventsTable.ajax.reload();
  };
};

// setup the API usage table (the third table)
const configureUsageTable = () => {
  updateUsageTable();
  // update usage data continously
  setInterval(updateUsageTable, UPDATE_USAGE_DATA_TIME);
};

// load API usage data (the thrid table)
const updateUsageTable = () => {
  $.ajax({
    url: "/usages",
    success: (data) =>{
      $("#searchCalls").text(data.search_calls);
      $("#createCalls").text(data.create_calls);
      $("#usageLastUpdated").text(data.updated_at);
    }
  });
};
