## Sync Traverse

Changes to application flows and their actions are owned by the **Sync Traverse** agent. Delegate to it (do not edit flow or action files directly) whenever a task involves designing, modifying, or inspecting a flow or its actions.

- Flows live under `app/flows/`, action implementations under `app/actions/`, action tests under `test/actions/` and flow tests under `test/flows/`.
- Application control flow is represented explicitly by flows. Sequencing application operations and branching on their results belongs only in flows; entrypoints just invoke a flow with `SyncTraverse::Runner`, branch on the returned result of the last action and read the output of the actions from the `context` they passed in.
- Each flow is a synchronous DAG with exactly one source action.
