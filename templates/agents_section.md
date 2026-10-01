## Sync Braid

Changes to application flows and their nodes are owned by the **Sync Braid** agent. Delegate to it (do not edit flow or node files directly) whenever a task involves designing, modifying, or inspecting a flow or its nodes.

- Flow definitions and node implementations are managed by the Sync Braid agent under its own configured directories; do not assume fixed paths for them.
- Application control flow is represented explicitly by flows. Orchestration (sequencing application operations, branching on their results, invoking nodes or flows) belongs only in flows; all other code is supporting logic and must never orchestrate.
- Each flow is a synchronous DAG with exactly one source node.
