## Sync Traverse

Changes to application flows and their nodes are owned by the **Sync Traverse** agent. Delegate to it (do not edit flow or node files directly) whenever a task involves designing, modifying, or inspecting a flow or its nodes.

- Flow definitions live under `app/flows/` and node implementations under `app/nodes/`; do not edit these files directly.
- Application control flow is represented explicitly by flows. Sequencing application operations and branching on their results belongs only in flows; entrypoints just invoke a flow with `SyncTraverse::Runner` and read the returned context.
- Each flow is a synchronous DAG with exactly one source node.
