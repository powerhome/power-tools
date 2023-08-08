import * as ReactDOM from "react-dom";
import React from "react";
import { AudienceEditor } from "@powerhome/audiences";

import "playbook-ui/dist/reset.css";
import "playbook-ui/dist/playbook.css";

import "@fortawesome/fontawesome-free/js/all.min.js";

document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll("div[data-context]").forEach((element) => {
    const uri = element.getAttribute("data-context");
    const scimUri = element.getAttribute("data-scim");

    ReactDOM.render(
      React.createElement(AudienceEditor, { uri, scimUri }),
      element
    );
  });
});
