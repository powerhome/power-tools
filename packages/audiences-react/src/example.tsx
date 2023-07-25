import "playbook-ui/dist/reset.css"
import "playbook-ui/dist/playbook.css"

import "@fortawesome/fontawesome-free/js/all.min.js"

import { StrictMode } from "react"
import ReactDOM from "react-dom"
import { Title } from "playbook-ui"

import AudienceForm from "./AudienceForm"
import {
  DepartmentGroupType,
  TerritoryGroupType,
  TitleGroupType,
} from "./types"

const rootNode = document.getElementById("root")
ReactDOM.render(
  <>
    <Title>Audiences Example</Title>
    <AudienceForm
      context={{
        context:
          "BAhJIh5naWQ6Ly9pZGluYWlkaS9Vc2VyLzM5NTk5BjoGRVQ=--81d7358dd5ee2ca33189bb404592df5e8d11420e",
        all: false,
        criteria: [
          {
            count: 10,
            groups: {
              Title: [
                {
                  groupType: "Title",
                  name: "Senior Developer",
                  id: "123",
                },
              ],
              Department: [
                {
                  groupType: "Department",
                  name: "Business Technology",
                  id: "123",
                },
              ],
              Territory: [
                {
                  groupType: "Territory",
                  name: "Philadelphia",
                  id: "1",
                },
              ],
            },
          },
          {
            count: 5,
            groups: {
              Title: [
                {
                  groupType: "Title",
                  name: "Director",
                  id: "123",
                },
              ],
              Department: [
                {
                  groupType: "Department",
                  name: "Business Technology",
                  id: "123",
                },
              ],
              Territory: [
                {
                  groupType: "Territory",
                  name: "Philadelphia",
                  id: "1",
                },
              ],
            },
          },
        ],
        extraMembers: [
          {
            id: "1",
            name: "Wade Winningham",
            groups: [],
            username: "wwinningham",
            photoUrl: "https://nitro.powerhrg.com/api/v1/users/1/avatar/badge",
          },
        ],
        totalMembers: 15,
      }}
      allowIndividuals
      onSave={(context) => console.log(context)}
      userOptions={[
        {
          id: "1",
          name: "Wade Winningham",
          groups: [],
          username: "wwinningham",
          photoUrl: "https://nitro.powerhrg.com/api/v1/users/1/avatar/badge",
        },
        {
          id: "2",
          name: "Tim Wenhold",
          groups: [],
          username: "twenhold",
          photoUrl: "https://nitro.powerhrg.com/api/v1/users/2/avatar/badge",
        },
      ]}
      groupTypes={[TitleGroupType, DepartmentGroupType, TerritoryGroupType]}
      groupOptions={{
        Territory: [
          {
            groupType: "Territory",
            name: "Philadelphia",
            id: "1",
          },
        ],
        Department: [
          {
            groupType: "Department",
            name: "Business Technology",
            id: "123",
          },
        ],
        Title: [
          {
            groupType: "Title",
            name: "Director",
            id: "123",
          },
          {
            groupType: "Title",
            name: "Developer",
            id: "321",
          },
        ],
      }}
    />
  </>,
  rootNode,
)
