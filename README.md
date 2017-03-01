Go's `context` (https://golang.org/pkg/context/) solves two important problems
for concurrent programming. First, it provides a mechanism for sharing a safe
cancellation mechanism. Second, it provides a safe abstraction for sharing
values between concurrent execution contexts.

Consider a program which spawns workers concurrently but then wants to terminate
them. The Context package provides a standard building block for providing this.

Now assume the same program encodes values into some protocol mechanism such
as HTTP headers or query parameters for spawned workers to access. The problem
with this is it results in brittleness; if a developer wishes to move some
value from a query parameter to a header, they must chase down every piece
of code that works thusly and edit it. The better approach is to eliminate
protocol details as early in the process of spawning workers entirely, and to
use a protocol-agnostic mechanism like a Context instance to communicate these
values safely to spawned workers.

It is often good practice to not make assumptions about the concurrent environment
library code will be used in, but the Context package only makes sense as a
building block for concurrent development, so it is enabled for safe use
in concurrent environments by default.

Like the Go equivalent, this library doesn't reduce keystrokes. Indeed, it
increases keystrokes as it implies adopting a new pattern for concurrent
development. 
