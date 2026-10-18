## Sync Traverse

Changes to application flows and their actions are owned by the **Sync Traverse** agent. Delegate to it (do not edit flow or action files directly) whenever a task involves designing, modifying, or inspecting a flow or its actions.

- Flows live under `app/flows/`, action implementations under `app/actions/`, action tests under `test/actions/` and flow tests under `test/flows/`.
- Application control flow is represented explicitly by flows. Sequencing application operations and branching on their results belongs only in flows; entrypoints just invoke a flow with `SyncTraverse::Runner`, branch on the returned result of the last action and read the output of the actions from the `context` they passed in.
- The `context` passed to a flow holds only the raw inputs of the entrypoint (params, the id of the current user), and the output of the actions is plain data or action-local objects, never application models or form objects. When wiring a flow into an entrypoint, adapt the entrypoint and its views to this output instead of computing values for the flow or converting its output back into application objects.
- Each flow is a synchronous DAG with exactly one source action.
- When reporting the work of the Sync Traverse agent, include its flow diagrams unchanged.
