## Sync Traverse

Changes to application flows and their nodes are owned by the **Sync Traverse** agent. Delegate to it (do not edit flow or node files directly) whenever a task involves designing, modifying, or inspecting a flow or its nodes.

- Flows live under `app/flows/`, node implementations under `app/nodes/` and node tests under `test/nodes/`; do not edit these files directly.
- Application control flow is represented explicitly by flows. Sequencing application operations and branching on their results belongs only in flows; entrypoints just invoke a flow with `SyncTraverse::Runner`, branch on the returned outcome of the last node and read results from the `context` they passed in.
- Each flow is a synchronous DAG with exactly one source node.
