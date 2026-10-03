-- dsseed.sql
-- Diagnostic Assessment and SkillGPS — Seed Data
--
-- Paste this script into the Supabase SQL Editor and run it AFTER dsschema.sql.
-- It inserts the reference data used by the Diagnostic module:
--   * exactly 1 program  (Bachelor of Science in Computer Science / BSCS)
--   * exactly 7 subjects
--   * exactly 49 topics   (7 per subject)
-- and, further down, the 980 diagnostic questions (added by task 1.4).
--
-- The script is idempotent: running it again on a Database that already holds
-- these rows leaves exactly 1 program, 7 subjects, and 49 topics with no
-- duplicates (Requirements 3.1-3.6). Idempotence is achieved by:
--   * programs  — ON CONFLICT (program_code) DO NOTHING (program_code is unique)
--   * subjects  — inserted only WHERE NOT EXISTS a row with the same name under
--                 the BSCS program (subjects has no unique constraint on name)
--   * topics    — ON CONFLICT (subject_id, topic_name) DO NOTHING using the
--                 unique pair constraint from the schema
--
-- Because primary keys are server-generated UUIDs, foreign keys are resolved by
-- looking rows up by their natural keys (program_code, subject_name,
-- topic_name) rather than by hardcoding ids.

-- ===========================================================================
-- 1. Program (Req 3.1)
-- ===========================================================================
insert into public.programs (program_name, program_code)
values ('Bachelor of Science in Computer Science', 'BSCS')
on conflict (program_code) do nothing;

-- ===========================================================================
-- 2. Subjects (Req 3.2) and Topics (Req 3.3, 3.4)
-- ===========================================================================
-- A single transactional DO block resolves the BSCS program id, inserts the
-- seven subjects idempotently, then inserts the seven topics per subject
-- idempotently. Descriptions are 1-300 characters with at least one
-- non-whitespace character (Req 3.3).
do $$
declare
  v_program_id uuid;
  v_subject_id uuid;
begin
  -- Resolve the BSCS program row inserted above.
  select id into v_program_id
  from public.programs
  where program_code = 'BSCS';

  if v_program_id is null then
    raise exception 'BSCS program row not found; run the programs insert first';
  end if;

  -- -------------------------------------------------------------------------
  -- Helper pattern repeated per subject:
  --   1. Insert the subject only if it does not already exist for BSCS.
  --   2. Resolve the subject id.
  --   3. Insert its seven topics, skipping any that already exist.
  -- -------------------------------------------------------------------------

  -- ---- Subject 1: Introduction to Programming -----------------------------
  insert into public.subjects (program_id, subject_name)
  select v_program_id, 'Introduction to Programming'
  where not exists (
    select 1 from public.subjects
    where program_id = v_program_id and subject_name = 'Introduction to Programming'
  );
  select id into v_subject_id from public.subjects
  where program_id = v_program_id and subject_name = 'Introduction to Programming';

  insert into public.topics (subject_id, topic_name, description) values
    (v_subject_id, 'Variables and Data Types', 'Declaring variables and understanding primitive and composite data types, their ranges, and type conversion.'),
    (v_subject_id, 'Operators and Expressions', 'Arithmetic, relational, logical, and assignment operators, operator precedence, and evaluating expressions.'),
    (v_subject_id, 'Conditional Statements', 'Branching program flow with if, else-if, else, and switch statements based on boolean conditions.'),
    (v_subject_id, 'Loops', 'Repeating work with for, while, and do-while loops, including break, continue, and loop termination.'),
    (v_subject_id, 'Functions', 'Defining and calling functions, parameters, return values, scope, and basic parameter passing.'),
    (v_subject_id, 'Arrays and Strings', 'Storing and indexing collections in arrays and manipulating text with common string operations.'),
    (v_subject_id, 'Recursion', 'Solving problems with functions that call themselves, base cases, and the call stack.')
  on conflict (subject_id, topic_name) do nothing;

  -- ---- Subject 2: Object-Oriented Programming -----------------------------
  insert into public.subjects (program_id, subject_name)
  select v_program_id, 'Object-Oriented Programming'
  where not exists (
    select 1 from public.subjects
    where program_id = v_program_id and subject_name = 'Object-Oriented Programming'
  );
  select id into v_subject_id from public.subjects
  where program_id = v_program_id and subject_name = 'Object-Oriented Programming';

  insert into public.topics (subject_id, topic_name, description) values
    (v_subject_id, 'Classes and Objects', 'Defining classes as blueprints and creating objects as instances with state and behavior.'),
    (v_subject_id, 'Encapsulation', 'Bundling data with methods and controlling access through visibility modifiers and accessors.'),
    (v_subject_id, 'Inheritance', 'Deriving classes from base classes to reuse and extend behavior through an is-a relationship.'),
    (v_subject_id, 'Polymorphism', 'Treating objects of different types through a common interface via overriding and dynamic dispatch.'),
    (v_subject_id, 'Abstraction and Interfaces', 'Modeling essential behavior with abstract classes and interfaces while hiding implementation detail.'),
    (v_subject_id, 'Constructors and Object Lifecycle', 'Initializing objects with constructors and understanding creation, use, and destruction phases.'),
    (v_subject_id, 'Exception Handling', 'Handling runtime errors with try, catch, finally, and throwing and propagating exceptions.')
  on conflict (subject_id, topic_name) do nothing;

  -- ---- Subject 3: Data Structures and Algorithms --------------------------
  insert into public.subjects (program_id, subject_name)
  select v_program_id, 'Data Structures and Algorithms'
  where not exists (
    select 1 from public.subjects
    where program_id = v_program_id and subject_name = 'Data Structures and Algorithms'
  );
  select id into v_subject_id from public.subjects
  where program_id = v_program_id and subject_name = 'Data Structures and Algorithms';

  insert into public.topics (subject_id, topic_name, description) values
    (v_subject_id, 'Arrays and Linked Lists', 'Contiguous arrays versus node-based linked lists and the trade-offs in access and insertion.'),
    (v_subject_id, 'Stacks and Queues', 'Last-in-first-out stacks and first-in-first-out queues and their typical operations and uses.'),
    (v_subject_id, 'Trees', 'Hierarchical structures such as binary trees and binary search trees, traversals, and properties.'),
    (v_subject_id, 'Graphs', 'Vertices and edges, directed and undirected graphs, representations, and traversal strategies.'),
    (v_subject_id, 'Sorting Algorithms', 'Comparison and non-comparison sorts, their mechanics, stability, and time complexity.'),
    (v_subject_id, 'Searching Algorithms', 'Linear and binary search and search strategies over sorted and unsorted collections.'),
    (v_subject_id, 'Algorithm Complexity', 'Analyzing running time and space with Big-O notation and best, average, and worst cases.')
  on conflict (subject_id, topic_name) do nothing;

  -- ---- Subject 4: Database Management Systems -----------------------------
  insert into public.subjects (program_id, subject_name)
  select v_program_id, 'Database Management Systems'
  where not exists (
    select 1 from public.subjects
    where program_id = v_program_id and subject_name = 'Database Management Systems'
  );
  select id into v_subject_id from public.subjects
  where program_id = v_program_id and subject_name = 'Database Management Systems';

  insert into public.topics (subject_id, topic_name, description) values
    (v_subject_id, 'Relational Model', 'Relations, tuples, attributes, keys, and the foundations of relational data organization.'),
    (v_subject_id, 'SQL Fundamentals', 'Core SQL for querying and modifying data with SELECT, INSERT, UPDATE, DELETE, and filtering.'),
    (v_subject_id, 'Joins and Subqueries', 'Combining rows across tables with inner and outer joins and nesting queries as subqueries.'),
    (v_subject_id, 'Entity-Relationship Modeling', 'Designing schemas with entities, attributes, and relationships expressed in ER diagrams.'),
    (v_subject_id, 'Normalization', 'Reducing redundancy and anomalies through normal forms and functional dependencies.'),
    (v_subject_id, 'Transactions and ACID', 'Grouping operations into transactions with atomicity, consistency, isolation, and durability.'),
    (v_subject_id, 'Indexing', 'Speeding up queries with indexes, index structures, and the trade-offs they introduce.')
  on conflict (subject_id, topic_name) do nothing;

  -- ---- Subject 5: Operating Systems ---------------------------------------
  insert into public.subjects (program_id, subject_name)
  select v_program_id, 'Operating Systems'
  where not exists (
    select 1 from public.subjects
    where program_id = v_program_id and subject_name = 'Operating Systems'
  );
  select id into v_subject_id from public.subjects
  where program_id = v_program_id and subject_name = 'Operating Systems';

  insert into public.topics (subject_id, topic_name, description) values
    (v_subject_id, 'Processes and Threads', 'Programs in execution as processes and lightweight threads sharing a process address space.'),
    (v_subject_id, 'CPU Scheduling', 'Choosing which ready process runs next using scheduling algorithms and performance metrics.'),
    (v_subject_id, 'Process Synchronization', 'Coordinating concurrent processes with locks, semaphores, and critical sections.'),
    (v_subject_id, 'Deadlocks', 'Conditions that cause deadlock and strategies to prevent, avoid, detect, and recover from it.'),
    (v_subject_id, 'Memory Management', 'Allocating and protecting memory with partitions, paging, and segmentation.'),
    (v_subject_id, 'Virtual Memory', 'Extending usable memory with paging to disk, page replacement, and handling page faults.'),
    (v_subject_id, 'File Systems', 'Organizing persistent storage with files, directories, allocation methods, and metadata.')
  on conflict (subject_id, topic_name) do nothing;

  -- ---- Subject 6: Computer Networks ---------------------------------------
  insert into public.subjects (program_id, subject_name)
  select v_program_id, 'Computer Networks'
  where not exists (
    select 1 from public.subjects
    where program_id = v_program_id and subject_name = 'Computer Networks'
  );
  select id into v_subject_id from public.subjects
  where program_id = v_program_id and subject_name = 'Computer Networks';

  insert into public.topics (subject_id, topic_name, description) values
    (v_subject_id, 'OSI and TCP/IP Models', 'Layered network reference models and how the OSI and TCP/IP layers map to one another.'),
    (v_subject_id, 'Data Link Layer and Switching', 'Framing, MAC addressing, error detection, and forwarding frames with switches.'),
    (v_subject_id, 'IP Addressing and Subnetting', 'IPv4 and IPv6 addressing, subnet masks, and dividing networks into subnets.'),
    (v_subject_id, 'Routing', 'Forwarding packets between networks using routing tables and routing protocols.'),
    (v_subject_id, 'Transport Layer Protocols', 'Reliable, connection-oriented TCP and lightweight connectionless UDP and their ports.'),
    (v_subject_id, 'Application Layer Protocols', 'Common protocols such as HTTP, DNS, and SMTP that applications use over the network.'),
    (v_subject_id, 'Network Security Basics', 'Fundamentals of securing networks with encryption, authentication, and firewalls.')
  on conflict (subject_id, topic_name) do nothing;

  -- ---- Subject 7: Web Development ------------------------------------------
  insert into public.subjects (program_id, subject_name)
  select v_program_id, 'Web Development'
  where not exists (
    select 1 from public.subjects
    where program_id = v_program_id and subject_name = 'Web Development'
  );
  select id into v_subject_id from public.subjects
  where program_id = v_program_id and subject_name = 'Web Development';

  insert into public.topics (subject_id, topic_name, description) values
    (v_subject_id, 'HTML Fundamentals', 'Structuring web content with semantic HTML elements, attributes, and document structure.'),
    (v_subject_id, 'CSS Layout and Styling', 'Styling pages and arranging layout with the box model, Flexbox, and Grid.'),
    (v_subject_id, 'JavaScript Fundamentals', 'Core JavaScript syntax, variables, types, functions, and control flow in the browser.'),
    (v_subject_id, 'DOM Manipulation and Events', 'Selecting and updating DOM nodes and responding to user interaction through events.'),
    (v_subject_id, 'Asynchronous JavaScript', 'Handling async work with callbacks, promises, and async/await and the event loop.'),
    (v_subject_id, 'Responsive Design', 'Adapting layouts across screen sizes with fluid grids, flexible media, and media queries.'),
    (v_subject_id, 'HTTP and REST APIs', 'Request/response over HTTP, methods and status codes, and consuming RESTful JSON APIs.')
  on conflict (subject_id, topic_name) do nothing;
end $$;

-- ===========================================================================
-- 3. Diagnostic questions (Req 4.1-4.11)
-- ===========================================================================
-- The 980 diagnostic questions (20 per topic) are appended below by task 1.4.
-- They are linked to topics by looking up topic_name within subject_name and
-- are inserted idempotently so re-running this script leaves exactly 20
-- questions per topic.

-- ===========================================================================
-- 3a. Diagnostic questions — 980 rows (20 per topic). Appended by task 1.4.
-- ===========================================================================
-- Idempotency (Req 4.11): each question is inserted only when no row with the
-- same topic_id and identical question text already exists. Re-running the
-- script therefore leaves exactly 20 questions per topic and inserts no
-- duplicates. topic_id is resolved by matching topic_name within subject_name
-- (natural keys), never by hardcoded UUIDs (Req 4.9).
do $$
declare
  v_topic_id uuid;
begin

  -- ---- Introduction to Programming / Variables and Data Types (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Introduction to Programming'
    and t.topic_name = 'Variables and Data Types';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Introduction to Programming', 'Variables and Data Types';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which data type is most appropriate for storing a person''s exact age in whole years?', 'Integer', 'Floating-point', 'Boolean', 'Character', 'A', 'An age in whole years has no fractional part, so an integer type stores it precisely without rounding.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which data type is most appropriate for storing a person''s exact age in whole years?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the result type when an integer is divided by a floating-point number in most languages?', 'Integer', 'Floating-point', 'Boolean', 'String', 'B', 'Mixed arithmetic promotes the integer to floating-point, so the result is a floating-point value.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the result type when an integer is divided by a floating-point number in most languages?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can comparing two floating-point values for exact equality be unreliable?', 'Floats cannot be compared at all', 'Equality always returns true for floats', 'Rounding error makes stored values slightly inexact', 'Floats are stored as text', 'C', 'Many decimals cannot be represented exactly in binary, so tiny rounding errors make exact equality fail.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can comparing two floating-point values for exact equality be unreliable?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does declaring a variable as a constant communicate to readers of the code?', 'It uses less memory', 'It is always an integer', 'It is visible to every function', 'Its value is not meant to change after assignment', 'D', 'A constant signals that the value is fixed once set, improving readability and preventing accidental reassignment.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does declaring a variable as a constant communicate to readers of the code?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'A variable declared inside a function but never initialized is best described as holding what?', 'An undefined or default value depending on the language', 'Exactly zero in every language', 'The last value of any other variable', 'A compile error in every language', 'A', 'Uninitialized locals hold a language-defined default or an undefined value; relying on it is unsafe.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'A variable declared inside a function but never initialized is best described as holding what?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which value fits a boolean variable?', '42', 'true', '"yes"', '3.14', 'B', 'A boolean holds only logical truth values such as true or false.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which value fits a boolean variable?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the main reason to choose an unsigned integer type over a signed one?', 'It stores decimals', 'It runs faster on all hardware', 'It doubles the positive range for the same bits', 'It prevents overflow entirely', 'C', 'Dropping the sign bit lets all bits represent magnitude, roughly doubling the maximum positive value.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the main reason to choose an unsigned integer type over a signed one?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens conceptually during an implicit type conversion?', 'The programmer rewrites the value by hand', 'The variable is deleted', 'The value becomes a string', 'The language converts a value to another type automatically', 'D', 'Implicit conversion (coercion) is performed by the language automatically when types differ in an expression.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens conceptually during an implicit type conversion?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Storing the text "123" is different from storing the number 123 because the text is what kind of data?', 'A string of characters', 'A floating-point value', 'A boolean', 'An integer in disguise', 'A', 'Quotes make "123" a string, a sequence of characters, not a numeric value you can do arithmetic on directly.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Storing the text "123" is different from storing the number 123 because the text is what kind of data?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which statement about variable scope is correct?', 'Scope sets the variable''s data type', 'Scope limits where a variable name can be used', 'Scope is the memory address of a variable', 'Scope is the number of bits a variable uses', 'B', 'Scope defines the region of code in which a declared name is visible and usable.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which statement about variable scope is correct?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why might a 32-bit signed integer overflow when adding two large positive numbers?', 'Addition is not supported for integers', 'The numbers were strings', 'The sum exceeds the maximum representable value', 'Overflow only affects floats', 'C', 'If the true sum is larger than the type''s maximum, the result wraps around, producing an incorrect value.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why might a 32-bit signed integer overflow when adding two large positive numbers?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What distinguishes a dynamically typed language from a statically typed one?', 'It cannot store integers', 'It has no variables', 'It never reports type errors', 'Variable types are checked at run time rather than compile time', 'D', 'In dynamic typing the type is associated with the value at run time, so type checks happen as the program runs.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What distinguishes a dynamically typed language from a statically typed one?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which choice best describes a character data type?', 'It stores a single symbol such as a letter or digit', 'It stores a whole paragraph', 'It stores only numbers', 'It stores true or false', 'A', 'A character type holds one symbol, typically backed by a numeric character code.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which choice best describes a character data type?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the effect of assigning a new value to an existing variable?', 'Both values are kept', 'The old value is replaced by the new one', 'A new variable is created', 'The program stops', 'B', 'Assignment overwrites the storage the variable names, discarding the previous value.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the effect of assigning a new value to an existing variable?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why do many languages require variables to be declared before use?', 'It makes programs run slower on purpose', 'It hides the variable from the programmer', 'It lets the compiler allocate storage and check types', 'It converts the variable to a string', 'C', 'Declaration tells the compiler the name and type so it can reserve storage and verify usage.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why do many languages require variables to be declared before use?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which type is best for a flag that records whether a user is logged in?', 'Floating-point', 'String of digits', 'Character array', 'Boolean', 'D', 'A logged-in flag is a yes/no condition, which a boolean models directly and clearly.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which type is best for a flag that records whether a user is logged in?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the term ''literal'' mean in programming?', 'A fixed value written directly in the source code', 'A variable that changes often', 'A function parameter', 'A memory address', 'A', 'A literal is a constant value, such as 10 or "hello", written literally in the code.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the term ''literal'' mean in programming?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'If a language stores integers in 8 bits unsigned, what is the largest value it can hold?', '256', '255', '127', '128', 'B', 'Eight unsigned bits represent 0 through 2^8 - 1, which is 255.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'If a language stores integers in 8 bits unsigned, what is the largest value it can hold?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is a floating-point type suited to storing a measured temperature like 36.6?', 'It uses less memory than an integer', 'It cannot store negatives', 'It represents fractional values', 'It stores text more accurately', 'C', 'Floating-point types store numbers with fractional parts, which integers cannot represent.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is a floating-point type suited to storing a measured temperature like 36.6?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the practical difference between a variable''s name and its value?', 'They are always identical', 'The name is numeric; the value is text', 'The value labels storage; the name is the data', 'The name labels storage; the value is the data stored there', 'D', 'A name is an identifier for a storage location, while the value is the current content of that location.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the practical difference between a variable''s name and its value?');

  -- ---- Introduction to Programming / Operators and Expressions (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Introduction to Programming'
    and t.topic_name = 'Operators and Expressions';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Introduction to Programming', 'Operators and Expressions';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'In most languages, what does the expression 7 % 3 evaluate to?', '1', '2', '0', '3', 'A', 'The modulo operator returns the remainder of 7 divided by 3, which is 1.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'In most languages, what does the expression 7 % 3 evaluate to?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Given typical precedence, what does 2 + 3 * 4 evaluate to?', '20', '14', '24', '9', 'B', 'Multiplication binds tighter than addition, so 3 * 4 is computed first, then 2 is added, giving 14.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Given typical precedence, what does 2 + 3 * 4 evaluate to?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the value of the boolean expression (5 > 3) && (2 > 4)?', 'true', '5', 'false', 'it errors', 'C', 'The second operand is false, and logical AND is true only when both sides are true, so the result is false.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the value of the boolean expression (5 > 3) && (2 > 4)?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does short-circuit evaluation of A && B skip B when A is false?', 'B is always false', 'AND evaluates right to left', 'B is converted to true', 'The result is already determined to be false', 'D', 'If the left operand of AND is false the whole expression must be false, so the right operand is not evaluated.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does short-circuit evaluation of A && B skip B when A is false?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the expression 10 / 4 produce in a language using integer division?', '2', '2.5', '3', '2.0', 'A', 'Integer division discards the fractional part, so 10 / 4 yields 2.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the expression 10 / 4 produce in a language using integer division?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which operator checks equality of value in most C-style languages?', '=', '==', '!=', '>=', 'B', 'A single = assigns, while == compares two values for equality.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which operator checks equality of value in most C-style languages?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the result of the unary expression !true?', 'true', '1', 'false', '0', 'C', 'Logical NOT inverts a boolean, so !true is false.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the result of the unary expression !true?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'In the expression a = b = 5, what value does a receive when assignment is right-associative?', '0', 'b', 'undefined', '5', 'D', 'Right-associative assignment first sets b to 5, then assigns that result to a, so a becomes 5.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'In the expression a = b = 5, what value does a receive when assignment is right-associative?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the bitwise AND of 6 and 3 equal?', '2', '7', '9', '5', 'A', 'In binary 110 AND 011 is 010, which is 2.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the bitwise AND of 6 and 3 equal?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is the expression x++ different from ++x when used inside a larger expression?', 'They are identical in all uses', 'x++ yields the old value, ++x yields the new value', 'x++ decreases x', '++x does not change x', 'B', 'Post-increment returns the value before incrementing; pre-increment returns the value after incrementing.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is the expression x++ different from ++x when used inside a larger expression?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the ternary expression (score >= 60) ? "pass" : "fail" return when score is 72?', 'fail', '72', 'pass', 'true', 'C', 'The condition is true, so the ternary yields the first branch, "pass".', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the ternary expression (score >= 60) ? "pass" : "fail" return when score is 72?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which comparison expression is true when x equals 5?', 'x > 5', 'x != 5', 'x < 5', 'x <= 5', 'D', 'Five is less than or equal to five, so x <= 5 is true while the others are false.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which comparison expression is true when x equals 5?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the result of the logical OR expression false || true?', 'true', 'false', '0', 'error', 'A', 'OR is true when at least one operand is true, so false OR true is true.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the result of the logical OR expression false || true?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'In 2 ** 3 (exponentiation in languages that support it), what is the value?', '6', '8', '9', '23', 'B', 'The exponent operator raises 2 to the power 3, which is 8.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'In 2 ** 3 (exponentiation in languages that support it), what is the value?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can mixing a signed and unsigned integer in a comparison give surprising results?', 'Comparisons are random', 'Unsigned values become negative', 'The signed value may be converted to a large unsigned value', 'The compiler ignores one operand', 'C', 'Usual arithmetic conversions can turn a negative signed value into a huge unsigned value, flipping the comparison.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can mixing a signed and unsigned integer in a comparison give surprising results?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the compound assignment x += 3 do?', 'Compares x to 3', 'Sets x to 3', 'Subtracts 3 from x', 'Adds 3 to x and stores the result in x', 'D', 'The += operator is shorthand for x = x + 3.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the compound assignment x += 3 do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Evaluate the expression 1 == 1.0 in a language that compares numeric value.', 'true', 'false', 'error', '1', 'A', 'Numeric comparison promotes the integer to floating-point, and 1 equals 1.0, so the result is true.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Evaluate the expression 1 == 1.0 in a language that compares numeric value.');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the value of 8 >> 1 using a right shift?', '16', '4', '7', '9', 'B', 'Shifting bits right by one divides by two, so 8 >> 1 is 4.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the value of 8 >> 1 using a right shift?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which expression correctly tests that a number n is even?', 'n / 2 == 0', 'n % 2 == 1', 'n % 2 == 0', 'n * 2 == 0', 'C', 'A number is even when the remainder of dividing by two is zero.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which expression correctly tests that a number n is even?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why are parentheses often added to expressions even when precedence already gives the right result?', 'They change the data type', 'They speed up execution', 'They are required by every operator', 'They make the intended grouping clear to readers', 'D', 'Explicit parentheses improve readability and reduce mistakes, even when precedence alone would work.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why are parentheses often added to expressions even when precedence already gives the right result?');

  -- ---- Introduction to Programming / Conditional Statements (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Introduction to Programming'
    and t.topic_name = 'Conditional Statements';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Introduction to Programming', 'Conditional Statements';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an if statement use to decide whether to run its body?', 'A boolean condition', 'A loop counter', 'A return value only', 'A variable name', 'A', 'An if evaluates a boolean condition and runs its body only when that condition is true.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an if statement use to decide whether to run its body?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'In an if-else-if chain, how many of the branches execute for a single evaluation?', 'All of them', 'At most one', 'Exactly two', 'None, ever', 'B', 'Control enters the first branch whose condition is true and skips the rest, so at most one branch runs.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'In an if-else-if chain, how many of the branches execute for a single evaluation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is a switch statement sometimes preferred over a long if-else-if chain?', 'It can test ranges that if cannot', 'It runs on strings only', 'It clearly dispatches on one value''s many cases', 'It never needs a default', 'C', 'A switch is clearer when branching on the many discrete values of a single expression.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is a switch statement sometimes preferred over a long if-else-if chain?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the purpose of the default case in a switch statement?', 'Mark the first case', 'End the program', 'Repeat the switch', 'Handle values not matched by any case', 'D', 'The default case runs when none of the listed case labels match the switch value.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the purpose of the default case in a switch statement?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What commonly happens if a case in a C-style switch omits its break?', 'Execution falls through to the next case', 'The program crashes', 'The switch restarts', 'The case is skipped', 'A', 'Without break, control falls through and executes the following case''s statements too.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What commonly happens if a case in a C-style switch omits its break?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which condition correctly checks that x is between 1 and 10 inclusive?', 'x >= 1 || x <= 10', 'x >= 1 && x <= 10', '1 < x < 10', 'x > 1 && x < 10', 'B', 'Both bounds must hold, so the inclusive range needs AND with >= and <=.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which condition correctly checks that x is between 1 and 10 inclusive?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a nested if statement allow you to express?', 'Two loops at once', 'A function call', 'A condition evaluated only when an outer condition holds', 'A variable declaration', 'C', 'Nesting places an inner conditional inside a branch, so it is tested only when the outer condition is true.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a nested if statement allow you to express?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can the dangling-else problem occur without braces?', 'Else is not allowed without braces', 'If statements cannot nest', 'Braces slow the program', 'An else may bind to the wrong if', 'D', 'An else associates with the nearest unmatched if, which can differ from the programmer''s intent when braces are omitted.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can the dangling-else problem occur without braces?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What value must a condition evaluate to for an if body to be skipped?', 'false', 'true', 'zero only', 'any number', 'A', 'If the condition is false the body is skipped and control moves past the if.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What value must a condition evaluate to for an if body to be skipped?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which refactoring removes an unnecessary else after a branch that returns?', 'Add another nested if', 'Use a guard clause that returns early', 'Convert to a switch', 'Duplicate the condition', 'B', 'A guard clause returns early on the exceptional case, letting the main logic continue without an else.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which refactoring removes an unnecessary else after a branch that returns?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the condition if (list) typically test in languages with truthiness?', 'Whether the list is sorted', 'The list length exactly', 'Whether the value is considered truthy', 'Whether the list is a string', 'C', 'In such languages a value is coerced to a boolean, so the branch runs when the value is truthy.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the condition if (list) typically test in languages with truthiness?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'When comparing strings in a conditional, what is usually compared?', 'Only their lengths', 'Their memory sizes', 'Their first character only', 'Their contents according to the language''s rules', 'D', 'String comparison in a conditional compares content as defined by the language, not just length.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'When comparing strings in a conditional, what is usually compared?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why should the most likely or cheapest condition often be tested first in a chain?', 'It can reduce the work done on average', 'It changes the result', 'It is required by syntax', 'It prevents compilation', 'A', 'Testing a likely or cheap condition first lets common cases exit the chain quickly, improving average performance.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why should the most likely or cheapest condition often be tested first in a chain?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does combining conditions with || mean for the branch to run?', 'All conditions must be true', 'At least one condition must be true', 'No condition may be true', 'Exactly one must be false', 'B', 'Logical OR makes the branch run when any one of the combined conditions is true.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does combining conditions with || mean for the branch to run?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which is a correct way to test equality to one of several values?', 'x == 1 && 2 && 3', 'x = 1, 2, 3', 'x == 1 || x == 2 || x == 3', 'x in between 1 3', 'C', 'Each possibility is tested separately and joined with OR so any match triggers the branch.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which is a correct way to test equality to one of several values?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the risk of writing if (x = 5) instead of if (x == 5) in C-style code?', 'It is a syntax error always', 'It compares addresses', 'It loops forever', 'It assigns 5 to x and tests a nonzero value', 'D', 'A single = assigns, so x becomes 5 and the condition tests that nonzero result, which is a common bug.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the risk of writing if (x = 5) instead of if (x == 5) in C-style code?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an early return inside a conditional accomplish?', 'It exits the function when the condition is met', 'It restarts the function', 'It skips to the next loop', 'It changes the return type', 'A', 'Returning inside a branch ends the function immediately for that case.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an early return inside a conditional accomplish?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why might you replace deeply nested conditionals with a lookup table?', 'To make the code slower', 'To simplify logic that maps inputs to outputs', 'To avoid using variables', 'Because conditions cannot nest', 'B', 'When branches merely map discrete inputs to outputs, a table can express the mapping more clearly than nested ifs.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why might you replace deeply nested conditionals with a lookup table?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What boolean result does the condition !(a == b) give when a differs from b?', 'false', 'a', 'true', 'b', 'C', 'a == b is false when they differ, and NOT false is true.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What boolean result does the condition !(a == b) give when a differs from b?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'In a guard that checks input validity before processing, where is it usually placed?', 'After all processing', 'Inside the deepest loop', 'In a separate file', 'At the top of the function before main logic', 'D', 'Validity guards run first so invalid input is rejected before the main logic executes.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'In a guard that checks input validity before processing, where is it usually placed?');

  -- ---- Introduction to Programming / Loops (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Introduction to Programming'
    and t.topic_name = 'Loops';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Introduction to Programming', 'Loops';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which loop is most natural when the number of iterations is known in advance?', 'A for loop', 'A while loop with no counter', 'A do-while loop', 'An if statement', 'A', 'A for loop packages initialization, condition, and update, making counted iteration clear.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which loop is most natural when the number of iterations is known in advance?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What distinguishes a do-while loop from a while loop?', 'It cannot use a counter', 'Its body always runs at least once', 'It never checks a condition', 'It runs forever', 'B', 'A do-while tests the condition after the body, so the body executes at least one time.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What distinguishes a do-while loop from a while loop?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the break statement do inside a loop?', 'Skips to the next iteration', 'Restarts the loop', 'Exits the loop immediately', 'Pauses execution', 'C', 'break terminates the enclosing loop and transfers control to the statement after it.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the break statement do inside a loop?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does continue do inside a loop?', 'Exits the loop', 'Repeats the whole loop', 'Ends the program', 'Skips the rest of the current iteration', 'D', 'continue abandons the current iteration and proceeds to the loop''s next iteration.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does continue do inside a loop?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does the loop while (i < n) with i never changing cause an infinite loop?', 'The condition never becomes false', 'n is always zero', 'while loops cannot end', 'i is a constant by rule', 'A', 'If nothing updates i, the condition stays true forever, so the loop never terminates.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does the loop while (i < n) with i never changing cause an infinite loop?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'For a loop that runs from i = 0 while i < 5, how many iterations occur?', '4', '5', '6', '0', 'B', 'i takes values 0,1,2,3,4 before the condition fails, which is five iterations.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'For a loop that runs from i = 0 while i < 5, how many iterations occur?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is an off-by-one error in loop bounds?', 'Using the wrong variable type', 'Forgetting to declare the counter', 'Iterating one time too many or too few', 'Nesting loops incorrectly', 'C', 'Off-by-one errors come from boundary conditions like < versus <=, causing one extra or missing iteration.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is an off-by-one error in loop bounds?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'In a nested loop, what does an unlabeled break affect?', 'Both loops', 'The outer loop only', 'The whole function', 'Only the innermost loop containing it', 'D', 'An unlabeled break exits just the loop that directly encloses it.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'In a nested loop, what does an unlabeled break affect?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which construct iterates directly over the elements of a collection?', 'A for-each loop', 'A plain if', 'A switch', 'A ternary', 'A', 'A for-each loop yields each element in turn without manual index management.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which construct iterates directly over the elements of a collection?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can modifying a collection while iterating over it be dangerous?', 'Loops cannot read collections', 'It may invalidate the iterator or skip elements', 'It always doubles the size', 'Iteration ignores changes safely', 'B', 'Adding or removing items during iteration can invalidate the iterator or cause elements to be skipped or repeated.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can modifying a collection while iterating over it be dangerous?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the typical structure of a for loop header?', 'condition; body; return', 'update; initialization; condition', 'initialization; condition; update', 'body; condition; break', 'C', 'A for header runs initialization once, tests the condition before each pass, and runs the update after each pass.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the typical structure of a for loop header?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How many times does a loop body run if the entry condition is false from the start in a while loop?', 'One', 'Infinite', 'Exactly the counter value', 'Zero', 'D', 'A while loop checks before running, so a false initial condition means the body never executes.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How many times does a loop body run if the entry condition is false from the start in a while loop?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the purpose of a sentinel value in a loop?', 'A special value that signals when to stop', 'The loop''s first element', 'The maximum counter', 'A nested loop marker', 'A', 'A sentinel is a marker value read as data that tells the loop to terminate.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the purpose of a sentinel value in a loop?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is sum initialized to 0 before a loop that accumulates values?', 'To make the loop infinite', 'To start the running total at a known base', 'To declare the loop counter', 'To stop the loop early', 'B', 'An accumulator must begin at an identity value, 0 for addition, so the first addition is correct.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is sum initialized to 0 before a loop that accumulates values?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a loop that counts down from n to 1 require in its update?', 'Incrementing the counter', 'Resetting the counter to n', 'Decrementing the counter each pass', 'Leaving the counter unchanged', 'C', 'Counting down means the update must decrease the counter so it eventually reaches the stopping bound.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a loop that counts down from n to 1 require in its update?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'In the loop for i in range equivalent that runs i = 1,3,5,..., what is the step?', '1', '3', '0', '2', 'D', 'Producing odd numbers means advancing the counter by two each iteration.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'In the loop for i in range equivalent that runs i = 1,3,5,..., what is the step?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is loop invariant reasoning used for?', 'Proving a property holds across iterations', 'Making loops run faster', 'Removing the loop condition', 'Counting iterations only', 'A', 'A loop invariant is a condition true before and after each iteration, used to reason about correctness.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is loop invariant reasoning used for?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why might you prefer a while loop over a for loop when reading input until end-of-file?', 'For loops cannot read input', 'The iteration count is unknown ahead of time', 'While loops are always faster', 'For loops ignore conditions', 'B', 'When you do not know how many items will arrive, a condition-driven while loop fits better than a counted for loop.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why might you prefer a while loop over a for loop when reading input until end-of-file?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens to a loop counter declared inside a for header after the loop ends?', 'It keeps its last value globally', 'It becomes a constant', 'It usually goes out of scope', 'It is sent to the caller', 'C', 'A counter declared in the for header is typically scoped to the loop and is not visible afterward.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens to a loop counter declared inside a for header after the loop ends?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which change converts a loop that prints 1..n into one that prints their sum?', 'Reverse the loop direction', 'Add a break at the start', 'Remove the condition', 'Accumulate each value into a total instead of printing', 'D', 'Replacing the print with an addition into a running total turns iteration into accumulation.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which change converts a loop that prints 1..n into one that prints their sum?');

  -- ---- Introduction to Programming / Functions (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Introduction to Programming'
    and t.topic_name = 'Functions';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Introduction to Programming', 'Functions';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the main benefit of organizing code into functions?', 'Reuse and reduced duplication', 'Slower execution', 'More global variables', 'Fewer comments', 'A', 'Functions package reusable logic so it can be called many times without repeating code.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the main benefit of organizing code into functions?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a function''s return value represent?', 'The function''s name', 'The result the function sends back to its caller', 'A loop counter', 'The number of parameters', 'B', 'A return value is the output the function produces and passes back to the code that called it.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a function''s return value represent?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the difference between a parameter and an argument?', 'They are the same thing', 'An argument is declared; a parameter is passed', 'A parameter is the declaration; an argument is the value passed', 'A parameter is always global', 'C', 'Parameters are named in the function definition; arguments are the actual values supplied at the call site.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the difference between a parameter and an argument?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'In pass-by-value, what does the function receive?', 'The original variable itself', 'A reference to global memory', 'Nothing at all', 'A copy of the argument', 'D', 'Pass-by-value copies the argument, so changes inside the function do not affect the caller''s variable.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'In pass-by-value, what does the function receive?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can a function that returns nothing still be useful?', 'It can produce side effects like printing', 'Functions must always return', 'It runs faster than others', 'It cannot take parameters', 'A', 'A void function performs an action, such as output or state change, without returning a value.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can a function that returns nothing still be useful?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a local variable in a function?', 'A variable shared by all functions', 'A variable visible only within that function', 'A function''s name', 'A permanent global value', 'B', 'Local variables exist only during the function''s execution and are not visible outside it.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a local variable in a function?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does recursion require a function to do?', 'Avoid all parameters', 'Return immediately', 'Call itself with a smaller problem', 'Use only global state', 'C', 'A recursive function solves a problem by calling itself on a reduced input toward a base case.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does recursion require a function to do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why do default parameter values help callers?', 'They forbid passing arguments', 'They make functions global', 'They remove the return value', 'Callers may omit arguments that have sensible defaults', 'D', 'Default values let a function be called with fewer arguments while supplying reasonable fallbacks.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why do default parameter values help callers?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is function overloading?', 'Multiple functions sharing a name but differing in parameters', 'A function that runs twice', 'A function with no body', 'A recursive function', 'A', 'Overloading defines several functions with the same name distinguished by their parameter lists.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is function overloading?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the call stack track during nested function calls?', 'The source file names', 'Return addresses and local state of active calls', 'The number of comments', 'Global constants only', 'B', 'Each active call pushes a frame holding its locals and where to return, forming the call stack.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the call stack track during nested function calls?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is a pure function easy to test?', 'It always prints results', 'It uses global variables', 'Its output depends only on its inputs with no side effects', 'It never returns', 'C', 'A pure function gives the same output for the same input and causes no side effects, so tests are deterministic.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is a pure function easy to test?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens when a function reaches a return statement?', 'It restarts from the top', 'It calls itself again', 'It ignores the value', 'It stops and gives control back to the caller', 'D', 'Reaching return ends the function''s execution and passes the value, if any, back to the caller.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens when a function reaches a return statement?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which describes passing an array to a function in languages that pass references?', 'The function can modify the caller''s array', 'The array is always copied', 'The array becomes read-only', 'The array is converted to text', 'A', 'When arrays are passed by reference, changes inside the function affect the caller''s array.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which describes passing an array to a function in languages that pass references?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a function signature?', 'Its body of statements', 'Its name together with its parameter types', 'Its return value at run time', 'Its line number', 'B', 'A signature identifies a function by its name and the number and types of its parameters.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a function signature?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why split a long function into smaller ones?', 'To add more global variables', 'To slow it down', 'To improve readability and reuse', 'To avoid returning values', 'C', 'Breaking a long function into focused smaller functions improves clarity, testing, and reuse.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why split a long function into smaller ones?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a recursive function need to avoid infinite recursion?', 'More parameters', 'A global counter', 'A larger stack only', 'A base case that stops the recursion', 'D', 'The base case handles the smallest input directly, ending the chain of recursive calls.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a recursive function need to avoid infinite recursion?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'In pass-by-reference, modifying the parameter inside the function does what?', 'Changes the caller''s original variable', 'Has no effect outside', 'Creates a copy', 'Deletes the variable', 'A', 'Pass-by-reference links the parameter to the caller''s variable, so modifications are visible to the caller.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'In pass-by-reference, modifying the parameter inside the function does what?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a return type?', 'The function''s first parameter', 'The kind of value a function hands back', 'The number of calls made', 'The function''s visibility', 'B', 'The return type declares what sort of value, if any, the function produces.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a return type?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can a variable name inside a function shadow a global of the same name?', 'Globals cannot exist', 'Shadowing deletes the global', 'The local name takes precedence within the function', 'The compiler merges them', 'C', 'A local declaration with the same name hides the global within the function''s scope, a situation called shadowing.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can a variable name inside a function shadow a global of the same name?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does it mean that a function is a first-class value in some languages?', 'It must be global', 'It cannot return', 'It runs only once', 'It can be stored in variables and passed as arguments', 'D', 'First-class functions can be assigned, passed, and returned like any other value.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does it mean that a function is a first-class value in some languages?');

  -- ---- Introduction to Programming / Arrays and Strings (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Introduction to Programming'
    and t.topic_name = 'Arrays and Strings';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Introduction to Programming', 'Arrays and Strings';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the index of the first element in a zero-based array?', '0', '1', '-1', 'the array length', 'A', 'Zero-based arrays number elements starting at 0, so the first element is at index 0.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the index of the first element in a zero-based array?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Accessing index 5 of an array that has 5 elements typically causes what?', 'A return of the first element', 'An out-of-bounds error or undefined behavior', 'A silent success', 'The array to grow', 'B', 'Valid indices are 0..4 for five elements, so index 5 is out of bounds.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Accessing index 5 of an array that has 5 elements typically causes what?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the length of the string "hello" equal?', '4', '6', '5', '1', 'C', 'The string contains five characters: h, e, l, l, o.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the length of the string "hello" equal?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why are arrays efficient for random access by index?', 'They search element by element', 'They use a hash table', 'They store a linked chain', 'Elements are stored contiguously so addresses are computed directly', 'D', 'Contiguous storage lets the address of any index be computed with simple arithmetic, giving constant-time access.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why are arrays efficient for random access by index?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is string concatenation?', 'Joining two strings end to end', 'Reversing a string', 'Counting characters', 'Splitting on spaces', 'A', 'Concatenation produces a new string by appending one string to the end of another.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is string concatenation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why are strings immutable in some languages?', 'They cannot be read', 'Operations create new strings rather than changing existing ones', 'They store only numbers', 'They are always empty', 'B', 'In languages with immutable strings, modifying a string yields a new string and leaves the original unchanged.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why are strings immutable in some languages?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a two-dimensional array model well?', 'A single value', 'A boolean flag', 'A grid or table of rows and columns', 'A function', 'C', 'A 2D array stores elements addressed by two indices, matching rows and columns of a grid.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a two-dimensional array model well?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How do you typically get the character at a given position in a string?', 'Call a sort function', 'Reverse the string', 'Convert it to a number', 'Index into the string like an array', 'D', 'Strings are commonly indexable, so position access retrieves the character at that index.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How do you typically get the character at a given position in a string?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the result of searching for a substring that is not present?', 'A sentinel such as -1 or a not-found indicator', 'The whole string', 'The first character', 'A crash in every language', 'A', 'Search routines usually return a sentinel like -1 or a special value to indicate the substring was not found.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the result of searching for a substring that is not present?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does inserting into the middle of an array cost more than appending at the end?', 'Arrays cannot be appended', 'Later elements must shift to make room', 'Insertion duplicates the array', 'Appending shifts everything', 'B', 'Middle insertion requires moving all subsequent elements, which is linear work, while appending is often constant.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does inserting into the middle of an array cost more than appending at the end?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does splitting a string on a delimiter produce?', 'A single longer string', 'The reversed string', 'A collection of substring pieces', 'A number', 'C', 'Splitting divides a string at each delimiter, yielding the pieces between delimiters.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does splitting a string on a delimiter produce?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the common way to iterate over all elements of an array?', 'Access only the last element', 'Use a single if', 'Call the array once', 'Loop from index 0 to length minus 1', 'D', 'A loop running indices 0..length-1 visits every element exactly once.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the common way to iterate over all elements of an array?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why might fixed-size arrays be limiting compared with dynamic arrays?', 'Their capacity is set and cannot grow easily', 'They cannot be indexed', 'They store only strings', 'They are always empty', 'A', 'A fixed-size array has a set capacity, so storing more elements requires allocating a new, larger array.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why might fixed-size arrays be limiting compared with dynamic arrays?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does trimming a string do?', 'Deletes the first character', 'Removes leading and trailing whitespace', 'Reverses the string', 'Counts the vowels', 'B', 'Trimming strips whitespace from the start and end, leaving the inner content intact.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does trimming a string do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How is a character often represented numerically?', 'By its array length', 'By a boolean', 'By a character code such as ASCII or Unicode', 'By a float', 'C', 'Characters map to integer code points, so comparisons and conversions use their numeric codes.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How is a character often represented numerically?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the expression arr[arr.length - 1] usually access?', 'The first element', 'A new element', 'An error always', 'The last element of the array', 'D', 'Length minus one is the index of the final element in a zero-based array.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the expression arr[arr.length - 1] usually access?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can comparing strings with == be unsafe in some languages?', 'It may compare references instead of contents', 'It always returns true', 'Strings cannot be compared', 'It reverses the strings', 'A', 'In some languages == compares object identity, so content comparison needs a dedicated method.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can comparing strings with == be unsafe in some languages?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a jagged array?', 'A sorted array', 'An array whose rows can have different lengths', 'A one-element array', 'An array of booleans', 'B', 'A jagged array is an array of arrays whose inner arrays may differ in length.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a jagged array?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does reversing the array [1,2,3] produce?', '[1,2,3]', '[2,1,3]', '[3,2,1]', '[3,1,2]', 'C', 'Reversing swaps the order of elements end to end, giving [3,2,1].', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does reversing the array [1,2,3] produce?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is building a long result by repeated string concatenation sometimes slow?', 'Strings cannot be joined', 'It uses no memory', 'Concatenation sorts the text', 'Each concatenation may copy the whole string so far', 'D', 'With immutable strings each concatenation can copy existing content, so repeated joins grow costly.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is building a long result by repeated string concatenation sometimes slow?');

  -- ---- Introduction to Programming / Recursion (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Introduction to Programming'
    and t.topic_name = 'Recursion';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Introduction to Programming', 'Recursion';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What are the two essential parts of a correct recursive function?', 'A base case and a recursive case', 'Two loops', 'A global variable and a return', 'An array and a string', 'A', 'Recursion needs a base case to stop and a recursive case that moves toward it.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What are the two essential parts of a correct recursive function?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens if a recursive function lacks a reachable base case?', 'It returns zero', 'It recurses until the stack overflows', 'It becomes a loop', 'It runs once', 'B', 'Without a reachable base case the calls never stop, exhausting the call stack.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens if a recursive function lacks a reachable base case?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'For factorial defined as n * factorial(n-1), what is the base case?', 'factorial(n) = n', 'factorial(1) = 0', 'factorial(0) = 1', 'factorial(n) = n*n', 'C', 'Factorial terminates at 0 with value 1, which stops the recursion.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'For factorial defined as n * factorial(n-1), what is the base case?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does each recursive call add a frame to the call stack?', 'It deletes the previous frame', 'Recursion avoids the stack', 'Frames are optional', 'It must remember its state until the call returns', 'D', 'Each in-progress call keeps its locals and return point on the stack until its sub-call completes.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does each recursive call add a frame to the call stack?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the recursive definition of a sum from 1 to n look like?', 'sum(n) = n + sum(n-1)', 'sum(n) = n * sum(n-1)', 'sum(n) = sum(n)', 'sum(n) = n - 1', 'A', 'The sum of 1..n is n plus the sum of 1..n-1, with sum(0) = 0 as the base case.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the recursive definition of a sum from 1 to n look like?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can naive recursive Fibonacci be slow?', 'It uses no base case', 'It recomputes the same subproblems many times', 'It cannot be written', 'It stores all results', 'B', 'Branching recursion recalculates overlapping subproblems repeatedly, leading to exponential work.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can naive recursive Fibonacci be slow?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What technique stores results of recursive calls to avoid recomputation?', 'Iteration only', 'Compilation', 'Memoization', 'Overloading', 'C', 'Memoization caches computed results so repeated subproblems are answered from the cache.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What technique stores results of recursive calls to avoid recomputation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is tail recursion?', 'Recursion with two base cases', 'Recursion that never returns', 'Recursion using arrays', 'Recursion where the recursive call is the last action', 'D', 'In tail recursion the recursive call is the final operation, which some languages optimize into a loop.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is tail recursion?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does recursion naturally traverse a tree structure?', 'By recursing on each child subtree', 'By using a single loop', 'By sorting the tree', 'By ignoring children', 'A', 'A tree''s recursive structure maps directly to recursive calls on each subtree.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does recursion naturally traverse a tree structure?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What converts a recursive algorithm into an iterative one that uses explicit state?', 'Removing the base case', 'Using an explicit stack to mimic the call stack', 'Adding more parameters', 'Deleting the recursion only', 'B', 'An explicit stack can hold the pending work that recursion would otherwise keep on the call stack.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What converts a recursive algorithm into an iterative one that uses explicit state?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'For a recursion that halves its input each call, how does the depth grow with n?', 'Linearly', 'Quadratically', 'Logarithmically', 'It stays constant', 'C', 'Halving the input each step reaches the base case after about log n calls.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'For a recursion that halves its input each call, how does the depth grow with n?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is a base case checked before making the recursive call?', 'To speed up the stack', 'To skip the return', 'To add a frame', 'To stop before recursing on an invalid or terminal input', 'D', 'Testing the base case first ensures the function stops at the terminal input instead of recursing further.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is a base case checked before making the recursive call?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the call recursePrint(n-1) before a print produce for n=3?', 'It prints in increasing order 1 2 3', 'It prints 3 2 1', 'It prints only 3', 'It prints nothing', 'A', 'Recursing before printing defers each print until the deepest call returns, yielding ascending order.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the call recursePrint(n-1) before a print produce for n=3?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which problem is naturally expressed with recursion?', 'Adding two integers', 'Computing the depth of nested folders', 'Checking if a flag is true', 'Printing a constant', 'B', 'Nested, self-similar structures like folders within folders map cleanly onto recursion.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which problem is naturally expressed with recursion?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is mutual recursion?', 'A function calling itself twice', 'A loop inside recursion', 'Two functions that call each other', 'Recursion without a base case', 'C', 'Mutual recursion occurs when functions call one another in a cycle, each moving toward a base case.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is mutual recursion?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why must recursive calls make progress toward the base case?', 'To add more frames', 'To avoid returning', 'To use less code', 'Otherwise the recursion never terminates', 'D', 'Each call must reduce the problem so the base case is eventually reached and recursion stops.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why must recursive calls make progress toward the base case?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What value does a correctly written power(2, 3) recursive function return?', '8', '6', '9', '5', 'A', 'Recursively multiplying 2 three times gives 2*2*2 = 8.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What value does a correctly written power(2, 3) recursive function return?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What risk does very deep recursion carry even with a correct base case?', 'Infinite output', 'Stack overflow from too many frames', 'Loss of the return value', 'Compilation failure', 'B', 'Even correct recursion can exceed the stack limit if the depth is extremely large.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What risk does very deep recursion carry even with a correct base case?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does recursion solve the Tower of Hanoi?', 'Move all disks at once', 'Sort the disks first', 'Move n-1 disks, move the largest, then move n-1 again', 'Use a single move', 'C', 'The classic solution recursively relocates the top n-1 disks, moves the largest, then relocates the n-1 disks.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does recursion solve the Tower of Hanoi?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the relationship between a recursive and an iterative solution to the same problem?', 'Only recursion can be correct', 'They never give the same result', 'Iteration cannot replace recursion', 'Both can compute the same result with different control flow', 'D', 'Many problems can be solved either way; recursion and iteration are interchangeable control structures.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the relationship between a recursive and an iterative solution to the same problem?');

  -- ---- Object-Oriented Programming / Classes and Objects (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Object-Oriented Programming'
    and t.topic_name = 'Classes and Objects';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Object-Oriented Programming', 'Classes and Objects';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the relationship between a class and an object?', 'A class is a blueprint and an object is an instance of it', 'An object defines a class', 'They are identical terms', 'A class is created from an object', 'A', 'A class describes structure and behavior; an object is a concrete instance created from that description.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the relationship between a class and an object?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an object''s state consist of?', 'Only its method names', 'The current values of its fields', 'The class file size', 'The number of classes', 'B', 'An object''s state is the set of values held in its instance fields at a point in time.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an object''s state consist of?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a method in object-oriented programming?', 'A standalone global variable', 'A file of constants', 'A function that belongs to a class and acts on objects', 'A type of loop', 'C', 'A method is a function defined within a class that operates on instances of that class.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a method in object-oriented programming?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why do two objects of the same class each have their own instance fields?', 'Fields are shared globally', 'Classes forbid fields', 'They share one memory slot', 'Each instance stores independent state', 'D', 'Instance fields belong to each object separately, so each object maintains its own state.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why do two objects of the same class each have their own instance fields?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the keyword referring to the current object (this/self) let a method do?', 'Access the object''s own fields and methods', 'Delete the class', 'Create a new class', 'Call the compiler', 'A', 'The self/this reference lets a method refer to the instance it was invoked on.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the keyword referring to the current object (this/self) let a method do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a static (class) member?', 'A member unique to each object', 'A member shared by all instances of the class', 'A member that cannot be used', 'A member stored on the stack only', 'B', 'A static member belongs to the class itself and is shared across all instances rather than per object.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a static (class) member?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How do you typically create an object in a class-based language?', 'By calling a loop', 'By importing a file', 'By instantiating the class, often with new', 'By declaring a constant', 'C', 'Instantiation allocates an object from a class, commonly using a new expression or constructor call.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How do you typically create an object in a class-based language?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is it useful to model real-world things as objects?', 'It removes all functions', 'It avoids using memory', 'It forbids reuse', 'It bundles related data and behavior together', 'D', 'Objects group an entity''s data and the operations on that data, mirroring real-world concepts.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is it useful to model real-world things as objects?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What distinguishes an instance method from a static method?', 'An instance method needs an object; a static method does not', 'Static methods need an object', 'They are identical', 'Instance methods are global', 'A', 'Instance methods act on a specific object, while static methods belong to the class and need no instance.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What distinguishes an instance method from a static method?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens to an object when no references to it remain in a garbage-collected language?', 'It is copied', 'It becomes eligible for garbage collection', 'It runs its methods', 'It becomes a class', 'B', 'Once unreachable, an object can be reclaimed by the garbage collector to free memory.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens to an object when no references to it remain in a garbage-collected language?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does it mean that objects have identity?', 'All equal objects are the same object', 'Objects have no fields', 'Two objects can be distinct even with equal field values', 'Identity equals the class name', 'C', 'Identity means each object is distinct; two objects may hold equal values yet remain separate instances.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does it mean that objects have identity?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which best describes a field (attribute) of a class?', 'A loop inside the class', 'The class''s file path', 'A compiler flag', 'A named piece of data each object stores', 'D', 'A field is a named variable that holds part of an object''s state.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which best describes a field (attribute) of a class?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why might a class expose methods instead of letting callers read fields directly?', 'To control and validate how state is accessed', 'To hide the class name', 'To avoid creating objects', 'To remove methods', 'A', 'Methods let the class mediate access, enforcing rules and keeping internal representation flexible.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why might a class expose methods instead of letting callers read fields directly?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the result of calling a method on an object?', 'A new class is defined', 'The method runs with access to that object''s state', 'The program ends', 'The object is deleted', 'B', 'Invoking a method executes its body with the receiving object available through self/this.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the result of calling a method on an object?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does it mean to send a message to an object (in OOP terminology)?', 'To email its author', 'To print its address', 'To invoke one of its methods', 'To delete it', 'C', 'Message passing is the OOP metaphor for calling a method on an object.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does it mean to send a message to an object (in OOP terminology)?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can two variables referencing the same object both see a change made through one of them?', 'Objects are always copied', 'References cannot share objects', 'Changes are local to variables', 'They refer to the same underlying instance', 'D', 'When two references point to one object, a mutation through either reference is visible through both.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can two variables referencing the same object both see a change made through one of them?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a class member initializer used for?', 'Giving fields initial values when objects are created', 'Deleting fields', 'Renaming the class', 'Compiling the file', 'A', 'Initializers set starting values for fields as part of object construction.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a class member initializer used for?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does a method differ from a plain function conceptually?', 'A function cannot take arguments', 'A method is associated with an object and its state', 'A method cannot return', 'They are unrelated to classes', 'B', 'A method is bound to a class/object and can act on that object''s state, unlike a standalone function.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does a method differ from a plain function conceptually?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is encapsulated when you define a class for a bank account?', 'Only the account owner''s name', 'The database schema', 'The balance data and the operations on it', 'The entire program', 'C', 'The class bundles the account''s data, such as balance, with methods like deposit and withdraw.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is encapsulated when you define a class for a bank account?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why do objects support modeling behavior that depends on internal state?', 'Fields cannot be read by methods', 'State is always global', 'Behavior ignores state', 'Methods can produce results based on current field values', 'D', 'Because methods can read an object''s fields, their behavior can vary with the object''s current state.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why do objects support modeling behavior that depends on internal state?');

  -- ---- Object-Oriented Programming / Encapsulation (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Object-Oriented Programming'
    and t.topic_name = 'Encapsulation';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Object-Oriented Programming', 'Encapsulation';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the core idea of encapsulation?', 'Bundling data with methods and restricting direct access', 'Copying objects frequently', 'Running code in parallel', 'Sharing all fields globally', 'A', 'Encapsulation groups data and behavior while hiding internal details behind a controlled interface.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the core idea of encapsulation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a private field prevent?', 'Access from the class''s own methods', 'Direct access from outside the class', 'The field from storing data', 'The class from compiling', 'B', 'A private field is accessible only within its own class, blocking outside code from reading or writing it directly.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a private field prevent?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the purpose of a getter method?', 'To delete a field', 'To rename the class', 'To provide controlled read access to a field', 'To create a loop', 'C', 'A getter exposes a field''s value through a method, letting the class control or validate access.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the purpose of a getter method?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why might a setter validate its argument before assigning?', 'To slow the program', 'To hide the method', 'To avoid returning', 'To keep the object''s state consistent', 'D', 'A validating setter rejects invalid values, protecting the object from entering an inconsistent state.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why might a setter validate its argument before assigning?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is an invariant in the context of encapsulation?', 'A condition the object must always keep true', 'A loop counter', 'A static method', 'A file name', 'A', 'An invariant is a rule about an object''s state that its methods must preserve, such as balance >= 0.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is an invariant in the context of encapsulation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does hiding internal representation make code more maintainable?', 'Callers must know every field', 'Internals can change without affecting callers', 'It prevents all method calls', 'It removes classes', 'B', 'When internals are hidden behind an interface, the implementation can change while callers stay unaffected.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does hiding internal representation make code more maintainable?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which access level typically allows access only within the same class and subclasses?', 'Public', 'Private', 'Protected', 'Global', 'C', 'Protected members are visible to the declaring class and its subclasses but not to unrelated code.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which access level typically allows access only within the same class and subclasses?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What problem can exposing a mutable field directly cause?', 'The field becomes read-only', 'The class cannot compile', 'Methods disappear', 'Outside code can break the object''s invariants', 'D', 'Direct access lets external code change state arbitrarily, potentially violating the object''s invariants.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What problem can exposing a mutable field directly cause?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a public method represent in an encapsulated class?', 'Part of the class''s intended interface', 'A hidden implementation detail', 'A compiler directive', 'A private field', 'A', 'Public methods form the contract through which other code interacts with the object.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a public method represent in an encapsulated class?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is returning a copy of an internal collection sometimes preferred over the collection itself?', 'It is always faster', 'It prevents callers from mutating internal state', 'It deletes the collection', 'It makes the field public', 'B', 'Returning a copy stops external code from altering the object''s internal data through the returned reference.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is returning a copy of an internal collection sometimes preferred over the collection itself?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is information hiding?', 'Encrypting all data', 'Removing all methods', 'Concealing internal details behind a stable interface', 'Making every field public', 'C', 'Information hiding exposes only what callers need and conceals how the class achieves it.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is information hiding?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does encapsulation support changing a field''s type later?', 'Callers must be rewritten always', 'Fields can never change type', 'It forbids future changes', 'Accessor methods can adapt while callers stay the same', 'D', 'If access goes through methods, the field''s internal type can change while the public methods remain stable.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does encapsulation support changing a field''s type later?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a reasonable reason to make a helper method private?', 'It supports internal logic and is not part of the interface', 'It must be called by every class', 'It should be global', 'It cannot return a value', 'A', 'Private helpers encapsulate internal steps that callers should not depend on.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a reasonable reason to make a helper method private?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can encapsulation reduce bugs?', 'It removes all state', 'State changes funnel through controlled methods', 'It disables validation', 'It exposes every field', 'B', 'Centralizing state changes in methods makes it easier to enforce rules and locate defects.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can encapsulation reduce bugs?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does read-only exposure of a value usually involve?', 'A public field', 'A deleted field', 'A getter with no corresponding setter', 'A static constructor', 'C', 'Providing only a getter lets callers read a value without being able to change it.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does read-only exposure of a value usually involve?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the difference between an object''s interface and its implementation?', 'They are the same', 'The interface is private', 'The implementation is public', 'The interface is what callers use; the implementation is how it works', 'D', 'The interface is the exposed set of operations; the implementation is the hidden internal mechanism.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the difference between an object''s interface and its implementation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is global mutable state the opposite of good encapsulation?', 'Any code can change it, making behavior hard to reason about', 'It is always private', 'It cannot be read', 'It improves hiding', 'A', 'Global mutable state can be altered from anywhere, undermining the controlled access encapsulation provides.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is global mutable state the opposite of good encapsulation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does encapsulating validation inside a class guarantee?', 'Validation can be skipped', 'Every change goes through the same checks', 'Fields become public', 'The class cannot be used', 'B', 'When validation lives in the class''s methods, all state changes are subject to the same rules.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does encapsulating validation inside a class guarantee?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which is a sign of weak encapsulation?', 'Private fields with validating setters', 'A small public interface', 'Callers reaching into and modifying an object''s fields directly', 'Hidden helper methods', 'C', 'Direct external manipulation of fields indicates the object is not protecting its own state.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which is a sign of weak encapsulation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does encapsulation aid testing?', 'It removes all methods', 'It hides the tests', 'It forbids assertions', 'Behavior can be exercised through a clear public interface', 'D', 'A well-defined public interface gives tests a stable surface to drive and observe behavior.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does encapsulation aid testing?');

  -- ---- Object-Oriented Programming / Inheritance (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Object-Oriented Programming'
    and t.topic_name = 'Inheritance';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Object-Oriented Programming', 'Inheritance';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What relationship does inheritance express between a subclass and its superclass?', 'An is-a relationship', 'A has-a relationship', 'A uses-a relationship', 'A none-of relationship', 'A', 'Inheritance models an is-a relationship, where a subclass is a kind of its superclass.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What relationship does inheritance express between a subclass and its superclass?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a subclass inherit from its superclass?', 'Only private members', 'Accessible fields and methods', 'Nothing at all', 'Only the class name', 'B', 'A subclass inherits the superclass''s accessible members and can add or override them.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a subclass inherit from its superclass?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does method overriding allow a subclass to do?', 'Delete the superclass', 'Rename the method', 'Provide its own version of an inherited method', 'Hide all fields', 'C', 'Overriding lets a subclass redefine an inherited method to change its behavior.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does method overriding allow a subclass to do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can a superclass reference point to a subclass object?', 'References ignore types', 'Objects have no type', 'Subclasses are unrelated', 'A subclass instance is also an instance of the superclass', 'D', 'Because of the is-a relationship, a subclass object can be used wherever a superclass is expected.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can a superclass reference point to a subclass object?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the diamond problem associated with?', 'Ambiguity in multiple inheritance from a shared ancestor', 'Single inheritance', 'Interfaces only', 'Static methods', 'A', 'The diamond problem arises when a class inherits the same ancestor through two paths, causing ambiguity.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the diamond problem associated with?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does a subclass typically invoke the superclass''s version of a method?', 'By copying the method', 'Through a super/base reference', 'By deleting its own', 'It cannot do this', 'B', 'A super (or base) call explicitly invokes the inherited implementation from the superclass.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does a subclass typically invoke the superclass''s version of a method?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is favored over inheritance when a class merely needs another class''s functionality?', 'Multiple inheritance', 'Overloading', 'Composition', 'Global variables', 'C', 'Composition includes an instance of another class, often preferable to inheritance for reuse without tight coupling.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is favored over inheritance when a class merely needs another class''s functionality?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an abstract base class provide?', 'Only final methods', 'No methods at all', 'A complete runnable program', 'Common structure plus methods subclasses must implement', 'D', 'An abstract class defines shared behavior and declares abstract methods that subclasses complete.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an abstract base class provide?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can deep inheritance hierarchies become hard to maintain?', 'Changes high in the hierarchy ripple to many subclasses', 'They cannot compile', 'They remove all methods', 'They forbid overriding', 'A', 'A change to a base class can affect every descendant, so deep hierarchies increase coupling and fragility.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can deep inheritance hierarchies become hard to maintain?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens to a field in the superclass when a subclass is instantiated?', 'It is discarded', 'It becomes part of the subclass instance', 'It is made private', 'It is duplicated per method', 'B', 'Inherited fields are included in the subclass object''s state when it is created.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens to a field in the superclass when a subclass is instantiated?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the Liskov substitution principle about?', 'Classes must be final', 'Fields must be public', 'Subtypes should be usable wherever their base type is expected', 'Methods must be static', 'C', 'The principle says a subclass should honor the superclass''s contract so substituting it does not break callers.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the Liskov substitution principle about?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which keyword commonly marks a class that cannot be subclassed?', 'public', 'abstract', 'virtual', 'final (or sealed)', 'D', 'Marking a class final or sealed prevents other classes from inheriting from it.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which keyword commonly marks a class that cannot be subclassed?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does overriding differ from in terms of signatures?', 'Overriding keeps the signature; overloading changes parameters', 'Both change the name', 'Overriding changes the return only', 'They are identical', 'A', 'Overriding reuses the same signature in a subclass, whereas overloading uses the same name with different parameters.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does overriding differ from in terms of signatures?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is calling an overridden method on a base reference dynamically dispatched?', 'The reference type always wins', 'The actual object''s type determines which version runs', 'Dispatch is random', 'Methods never override', 'B', 'Dynamic dispatch selects the method based on the runtime type of the object, enabling polymorphism.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is calling an overridden method on a base reference dynamically dispatched?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a protected member''s role in inheritance?', 'It is public to all', 'It is invisible to subclasses', 'It is accessible to subclasses but not to outside code', 'It cannot be inherited', 'C', 'Protected members allow subclass access while keeping them hidden from unrelated code.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a protected member''s role in inheritance?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does extending a class with a new method, without changing existing ones, illustrate?', 'Breaking the superclass', 'Removing inheritance', 'Making the class abstract', 'Adding behavior through inheritance', 'D', 'A subclass can add new methods, extending behavior while leaving inherited members intact.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does extending a class with a new method, without changing existing ones, illustrate?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why might you make a method in a base class abstract?', 'To require each subclass to supply its own implementation', 'To stop the class compiling', 'To delete it later', 'To make it static', 'A', 'An abstract method defers implementation to subclasses, enforcing that each provides concrete behavior.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why might you make a method in a base class abstract?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the effect of a subclass not calling the superclass constructor explicitly in many languages?', 'No constructor runs', 'The no-argument superclass constructor runs by default', 'The subclass fails to exist', 'All fields become null forever', 'B', 'Many languages implicitly invoke the superclass''s no-argument constructor if the subclass does not call one.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the effect of a subclass not calling the superclass constructor explicitly in many languages?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which is a legitimate use of inheritance?', 'Making a Car contain an Engine via inheritance', 'Replacing all functions', 'Modeling a Car as a kind of Vehicle', 'Avoiding any shared behavior', 'C', 'A Car is-a Vehicle, so inheritance fits; an Engine is a part of a Car, which suits composition instead.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which is a legitimate use of inheritance?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What problem does overusing inheritance for code reuse cause?', 'Faster execution always', 'No reuse at all', 'Loss of all methods', 'Tight coupling and fragile hierarchies', 'D', 'Using inheritance purely to share code can couple unrelated classes and make the hierarchy brittle.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What problem does overusing inheritance for code reuse cause?');

  -- ---- Object-Oriented Programming / Polymorphism (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Object-Oriented Programming'
    and t.topic_name = 'Polymorphism';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Object-Oriented Programming', 'Polymorphism';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does polymorphism allow a single interface to do?', 'Represent different underlying types with suitable behavior', 'Delete all subclasses', 'Prevent method calls', 'Store only integers', 'A', 'Polymorphism lets one interface or reference work with many types, each responding appropriately.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does polymorphism allow a single interface to do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is runtime polymorphism achieved through?', 'Compile-time constants', 'Method overriding and dynamic dispatch', 'Static fields', 'Global variables', 'B', 'Overridden methods selected by the object''s runtime type give runtime (dynamic) polymorphism.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is runtime polymorphism achieved through?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is compile-time polymorphism commonly associated with?', 'Dynamic dispatch', 'Garbage collection', 'Method overloading', 'Inheritance depth', 'C', 'Overloading resolves which method to call at compile time based on argument types, a form of static polymorphism.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is compile-time polymorphism commonly associated with?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can a loop over a list of shapes call area() on each without knowing exact types?', 'All shapes are identical', 'area() is static', 'The list sorts shapes', 'Each shape overrides area() and dispatch picks the right one', 'D', 'Polymorphic dispatch invokes each object''s own area() implementation at runtime.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can a loop over a list of shapes call area() on each without knowing exact types?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a virtual method enable?', 'Overriding so the subclass version is called through a base reference', 'Preventing overriding', 'Static binding only', 'Removing the method', 'A', 'A virtual method is dispatched dynamically, so a subclass override runs even through a base-type reference.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a virtual method enable?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the result of upcasting a Dog to an Animal reference and calling an overridden speak()?', 'The Animal''s speak() runs', 'The Dog''s speak() runs', 'An error occurs', 'Nothing runs', 'B', 'Dynamic dispatch uses the actual object type, so the Dog''s overridden method executes.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the result of upcasting a Dog to an Animal reference and calling an overridden speak()?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which is an example of ad hoc polymorphism?', 'Inheriting fields', 'Allocating memory', 'Overloading a function for different argument types', 'Declaring a constant', 'C', 'Ad hoc polymorphism provides multiple implementations selected by argument types, as in overloading.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which is an example of ad hoc polymorphism?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is parametric polymorphism also known as?', 'Overriding', 'Encapsulation', 'Recursion', 'Generics', 'D', 'Parametric polymorphism, or generics, writes code that works uniformly over many types via type parameters.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is parametric polymorphism also known as?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does polymorphism reduce the need for large conditional type checks?', 'Each type carries its own behavior to invoke', 'Conditionals are illegal', 'Types cannot differ', 'It removes methods', 'A', 'Instead of branching on type, you call a polymorphic method and let each type respond, simplifying code.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does polymorphism reduce the need for large conditional type checks?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What must subclasses share to be used polymorphically through a base type?', 'Identical fields', 'A common interface or base method', 'The same memory address', 'No methods', 'B', 'Polymorphic use requires a shared interface or base-class method that each subtype implements or overrides.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What must subclasses share to be used polymorphically through a base type?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does subtype polymorphism rely on?', 'Removing inheritance', 'Static dispatch only', 'A subtype being substitutable for its supertype', 'Copying objects', 'C', 'Subtype polymorphism depends on substitutability: a subtype can stand in for its supertype.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does subtype polymorphism rely on?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens when you call a non-virtual method through a base reference in languages with that distinction?', 'The subclass version always runs', 'An error occurs', 'The method is skipped', 'The base version is used based on the reference type', 'D', 'Non-virtual methods bind statically to the reference''s declared type, not the object''s runtime type.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens when you call a non-virtual method through a base reference in languages with that distinction?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does polymorphism support the open-closed principle?', 'New types can be added without changing existing code', 'Existing code must be edited for each type', 'It closes the program', 'It forbids new types', 'A', 'By programming to interfaces, new polymorphic types can be introduced without modifying code that uses the interface.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does polymorphism support the open-closed principle?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which best describes method dispatch for an overridden method at runtime?', 'The variable''s name determines it', 'The object''s actual class determines the method', 'The file order determines it', 'It is chosen randomly', 'B', 'Dynamic dispatch resolves overridden methods using the object''s actual runtime class.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which best describes method dispatch for an overridden method at runtime?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is coercion polymorphism?', 'Overriding a method', 'Defining generics', 'Automatic conversion of a value to a compatible type', 'Hiding fields', 'C', 'Coercion polymorphism implicitly converts a value to a type the operation expects, such as int to double.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is coercion polymorphism?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can an interface-typed parameter accept many concrete classes?', 'Interfaces accept only one class', 'Parameters ignore types', 'Classes cannot implement interfaces', 'Any class implementing the interface qualifies', 'D', 'A parameter typed as an interface accepts any object whose class implements that interface.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can an interface-typed parameter accept many concrete classes?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does polymorphism combined with a common toString-like method enable?', 'Uniform formatting across different object types', 'Deleting objects', 'Sorting integers only', 'Blocking inheritance', 'A', 'A shared method overridden per type lets callers format diverse objects through one call.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does polymorphism combined with a common toString-like method enable?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a downside of relying on type checks and casts instead of polymorphism?', 'It is always faster', 'Code becomes brittle and must change for each new type', 'It removes all classes', 'It prevents compilation', 'B', 'Explicit type checks spread knowledge of every type across the code, making it fragile as types grow.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a downside of relying on type checks and casts instead of polymorphism?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What role does a base-class reference play in polymorphic collections?', 'It forbids subtypes', 'It stores only the base class', 'It lets the collection hold any subtype uniformly', 'It copies elements', 'C', 'Typing a collection by a base type allows it to store and treat any subtype instances uniformly.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What role does a base-class reference play in polymorphic collections?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is polymorphism considered a key pillar of object-oriented design?', 'It removes encapsulation', 'It bans inheritance', 'It eliminates objects', 'It lets one interface serve many implementations flexibly', 'D', 'Polymorphism enables flexible, extensible designs where behavior varies by type behind a common interface.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is polymorphism considered a key pillar of object-oriented design?');

  -- ---- Object-Oriented Programming / Abstraction and Interfaces (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Object-Oriented Programming'
    and t.topic_name = 'Abstraction and Interfaces';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Object-Oriented Programming', 'Abstraction and Interfaces';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an interface define?', 'A contract of methods a class must implement', 'The private fields of a class', 'A loop structure', 'The memory layout', 'A', 'An interface specifies methods that implementing classes must provide, without implementation.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an interface define?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is abstraction in object-oriented design?', 'Copying every field', 'Exposing essential behavior while hiding details', 'Running tasks in parallel', 'Deleting methods', 'B', 'Abstraction presents a simplified view, exposing what matters and hiding the implementation.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is abstraction in object-oriented design?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does an abstract class differ from an interface in many languages?', 'An interface has fields and constructors', 'They are identical', 'An abstract class can provide some implementation and state', 'An abstract class cannot be subclassed', 'C', 'Abstract classes may include concrete methods and fields, while interfaces traditionally declare only method signatures.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does an abstract class differ from an interface in many languages?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can a class implement multiple interfaces but often extend only one class?', 'Interfaces cannot be implemented', 'Classes forbid interfaces', 'Only one interface is allowed', 'Interfaces avoid the ambiguity of multiple implementation inheritance', 'D', 'Implementing several interfaces adds no inherited implementation to conflict, unlike multiple class inheritance.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can a class implement multiple interfaces but often extend only one class?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What must a concrete class do with the methods declared in an interface it implements?', 'Provide an implementation for each', 'Ignore them', 'Rename them', 'Make them private', 'A', 'A concrete class must implement every method the interface declares to satisfy the contract.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What must a concrete class do with the methods declared in an interface it implements?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is programming to an interface?', 'Writing only interfaces', 'Depending on an abstraction rather than a concrete type', 'Avoiding all classes', 'Using global variables', 'B', 'Coding against an interface decouples callers from specific implementations, improving flexibility.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is programming to an interface?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an abstract method look like?', 'A method with a full body', 'A private field', 'A declaration with no body', 'A static constant', 'C', 'An abstract method declares a signature without an implementation, to be completed by subclasses.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an abstract method look like?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can you not instantiate an abstract class directly?', 'It has too many fields', 'It is private', 'It lacks a name', 'It may have unimplemented methods', 'D', 'An abstract class may be incomplete, so it must be subclassed and completed before instantiation.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can you not instantiate an abstract class directly?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What benefit does abstraction give to large systems?', 'Components can interact through stable contracts', 'Every detail is exposed', 'Code cannot be reused', 'Modules merge into one', 'A', 'Abstraction lets modules depend on stable interfaces, reducing coupling in large systems.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What benefit does abstraction give to large systems?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a default method in an interface (where supported)?', 'A private field', 'A method with a provided implementation in the interface', 'An abstract constructor', 'A static class', 'B', 'Default methods let an interface supply an implementation that implementers can use or override.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a default method in an interface (where supported)?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How do interfaces enable polymorphism?', 'They forbid overriding', 'They store state only', 'Different classes implementing one interface are used interchangeably', 'They prevent multiple types', 'C', 'Code typed to an interface can accept any implementing class, enabling polymorphic behavior.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How do interfaces enable polymorphism?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does depending on abstractions rather than concretions help with?', 'Hiding the interface', 'Removing polymorphism', 'Forcing one implementation', 'Swapping implementations without changing callers', 'D', 'This dependency-inversion idea lets you replace implementations freely as long as the abstraction holds.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does depending on abstractions rather than concretions help with?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which is a good candidate to model as an interface?', 'A capability like Comparable or Printable', 'A specific car model', 'A single integer', 'A for loop', 'A', 'Capabilities that many unrelated classes can provide are well modeled as interfaces.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which is a good candidate to model as an interface?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens if a class claims to implement an interface but omits a required method?', 'It compiles and runs fine', 'It will not compile or must be abstract', 'The method is auto-generated correctly', 'The interface is deleted', 'B', 'Omitting a required method breaks the contract, so the class must implement it or be declared abstract.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens if a class claims to implement an interface but omits a required method?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is an interface sometimes called a type without implementation?', 'It has full method bodies', 'It stores runtime data', 'It defines what operations exist but not how', 'It is a concrete class', 'C', 'An interface specifies operations and their signatures, leaving the how to implementers.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is an interface sometimes called a type without implementation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What design smell does a very large interface with many unrelated methods suggest?', 'It is perfectly designed', 'It must become a class', 'It cannot be implemented', 'It should be split into smaller focused interfaces', 'D', 'The interface-segregation idea favors small, cohesive interfaces over one large, unfocused one.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What design smell does a very large interface with many unrelated methods suggest?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does abstraction relate to hiding complexity?', 'It presents a simple surface over complex internals', 'It exposes all internals', 'It removes functionality', 'It duplicates code', 'A', 'Abstraction offers a simplified interface, concealing complex implementation behind it.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does abstraction relate to hiding complexity?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What can an interface reference hold at runtime?', 'Only the interface itself', 'Any object whose class implements the interface', 'No objects', 'Only primitive values', 'B', 'A variable of interface type can reference any instance of a class implementing that interface.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What can an interface reference hold at runtime?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why do interfaces help with unit testing?', 'They prevent testing', 'They remove methods', 'Test doubles can implement the same interface', 'They hide the tests', 'C', 'An interface lets you substitute a fake or mock implementation during tests.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why do interfaces help with unit testing?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the main difference between abstraction and encapsulation?', 'They are identical', 'Abstraction exposes fields', 'Encapsulation exposes complexity', 'Abstraction hides complexity; encapsulation hides internal state', 'D', 'Abstraction focuses on exposing essential behavior; encapsulation focuses on protecting internal data.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the main difference between abstraction and encapsulation?');

  -- ---- Object-Oriented Programming / Constructors and Object Lifecycle (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Object-Oriented Programming'
    and t.topic_name = 'Constructors and Object Lifecycle';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Object-Oriented Programming', 'Constructors and Object Lifecycle';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the primary job of a constructor?', 'Initialize a new object''s state', 'Delete an object', 'Rename a class', 'Compile the program', 'A', 'A constructor runs when an object is created to set up its initial field values.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the primary job of a constructor?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'When is a constructor called?', 'Every time a method runs', 'When an instance of the class is created', 'Only at program exit', 'When a field is read', 'B', 'A constructor executes during object creation, before the object is used.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'When is a constructor called?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a default constructor?', 'A constructor with many parameters', 'A static method', 'A no-argument constructor provided or generated', 'A destructor', 'C', 'A default constructor takes no arguments and may be supplied automatically if none is defined.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a default constructor?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can a class have multiple constructors?', 'To delete objects faster', 'To avoid fields', 'To prevent instantiation', 'To support different ways of initializing objects', 'D', 'Overloaded constructors offer several initialization paths with different parameter sets.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can a class have multiple constructors?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does constructor chaining accomplish?', 'One constructor calls another to reuse initialization', 'It deletes constructors', 'It prevents inheritance', 'It renames fields', 'A', 'Chaining lets a constructor delegate to another, avoiding duplicated initialization code.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does constructor chaining accomplish?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'In inheritance, what runs before a subclass constructor body?', 'The subclass destructor', 'The superclass constructor', 'A static block only', 'Nothing', 'B', 'The superclass is initialized first, so its constructor runs before the subclass constructor body.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'In inheritance, what runs before a subclass constructor body?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the purpose of a destructor or finalizer?', 'Create new objects', 'Rename the class', 'Release resources when an object is destroyed', 'Start the program', 'C', 'A destructor/finalizer performs cleanup, such as releasing resources, as an object''s lifecycle ends.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the purpose of a destructor or finalizer?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'In garbage-collected languages, why is explicit resource cleanup still sometimes needed?', 'GC never runs', 'Objects never die', 'Memory is infinite', 'Garbage collection does not promptly release non-memory resources', 'D', 'GC reclaims memory but may delay or ignore external resources like files, so explicit cleanup is used.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'In garbage-collected languages, why is explicit resource cleanup still sometimes needed?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What problem does a constructor that leaves fields uninitialized risk?', 'The object may be in an invalid state', 'The object cannot exist', 'The class is deleted', 'Methods never run', 'A', 'Failing to initialize required fields can leave the object in an inconsistent or invalid state.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What problem does a constructor that leaves fields uninitialized risk?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the new expression typically do?', 'Only allocate without initializing', 'Allocate and initialize an object', 'Delete an object', 'Rename a variable', 'B', 'A new expression allocates memory for an object and invokes its constructor to initialize it.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the new expression typically do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why might a constructor throw an exception?', 'To speed up creation', 'To skip the body', 'To signal that valid initialization is impossible', 'To rename the object', 'C', 'If arguments or state make a valid object impossible, a constructor can throw to prevent a half-built object.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why might a constructor throw an exception?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a copy constructor?', 'A constructor with no parameters', 'A static initializer', 'A destructor', 'A constructor that initializes a new object from an existing one', 'D', 'A copy constructor creates a new object as a copy of another instance of the same class.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a copy constructor?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What phase follows construction in an object''s lifecycle?', 'Use through its methods', 'Immediate destruction always', 'Recompilation', 'Renaming', 'A', 'After construction, an object is used via its methods until it is no longer needed.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What phase follows construction in an object''s lifecycle?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is leaking a reference to this from a constructor risky?', 'It speeds up GC', 'Other code may see a partially initialized object', 'It renames the field', 'It prevents construction', 'B', 'Publishing this before construction finishes can expose an incompletely initialized object to other code.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is leaking a reference to this from a constructor risky?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a static initializer block do?', 'Create each object', 'Run on every method call', 'Initialize static state when the class loads', 'Delete the class', 'C', 'A static initializer runs once as the class is loaded to set up class-level state.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a static initializer block do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What should a constructor avoid doing for predictable objects?', 'Assigning fields', 'Validating arguments', 'Calling super', 'Starting complex background work or heavy side effects', 'D', 'Keeping constructors focused on initialization avoids surprising side effects during object creation.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What should a constructor avoid doing for predictable objects?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is object initialization order typically?', 'Fields and super first, then the constructor body', 'Constructor body before fields', 'Destructor first', 'Methods before fields', 'A', 'Superclass and field initialization generally precede the subclass constructor body.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is object initialization order typically?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why do some designs use a factory method instead of a public constructor?', 'To forbid objects', 'To control or vary which object is created', 'To rename the class', 'To skip initialization', 'B', 'A factory method can encapsulate creation logic, return subtypes, or reuse instances, unlike a plain constructor.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why do some designs use a factory method instead of a public constructor?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the lifecycle state of an object with no remaining references in a GC language?', 'Still actively used', 'Being constructed', 'Unreachable and collectible', 'Private', 'C', 'An object with no references is unreachable and becomes eligible for garbage collection.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the lifecycle state of an object with no remaining references in a GC language?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does initializing a field at its declaration provide?', 'A destructor', 'A new class', 'A loop', 'A default value before the constructor runs', 'D', 'Field initializers set starting values, applied as the object is constructed.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does initializing a field at its declaration provide?');

  -- ---- Object-Oriented Programming / Exception Handling (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Object-Oriented Programming'
    and t.topic_name = 'Exception Handling';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Object-Oriented Programming', 'Exception Handling';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the purpose of a try block?', 'To wrap code that might raise an exception', 'To define a class', 'To loop forever', 'To declare a field', 'A', 'A try block encloses code whose exceptions can be caught and handled nearby.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the purpose of a try block?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a catch block do?', 'Throw a new class', 'Handle a thrown exception of a matching type', 'Initialize fields', 'End the program silently', 'B', 'A catch block receives and handles an exception whose type it is declared to catch.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a catch block do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'When does a finally block run?', 'Only when no exception occurs', 'Only on exceptions', 'Whether or not an exception was thrown', 'Never', 'C', 'A finally block executes after the try/catch regardless of whether an exception occurred, for cleanup.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'When does a finally block run?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens to an exception that is not caught anywhere?', 'It is ignored silently', 'It becomes a return value', 'It restarts the function', 'It propagates up and may terminate the program', 'D', 'An uncaught exception unwinds the call stack and typically ends the program with an error.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens to an exception that is not caught anywhere?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is catching a very broad exception type often discouraged?', 'It can hide bugs by swallowing unexpected errors', 'It is illegal syntax', 'It speeds up code', 'It removes the try block', 'A', 'Catching too broadly can mask programming errors you did not intend to handle.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is catching a very broad exception type often discouraged?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the difference between a checked and an unchecked exception (where that distinction exists)?', 'They are identical', 'Checked exceptions must be declared or handled; unchecked need not', 'Unchecked must always be caught', 'Checked exceptions cannot be thrown', 'B', 'Checked exceptions require explicit handling or declaration, while unchecked ones do not.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the difference between a checked and an unchecked exception (where that distinction exists)?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does throwing an exception do to the current method?', 'It returns normally', 'It restarts the method', 'It stops normal flow and transfers control to a handler', 'It ignores the error', 'C', 'Throwing aborts normal execution and searches up the stack for a matching handler.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does throwing an exception do to the current method?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why re-throw an exception after partially handling it?', 'To delete it', 'To speed up the stack', 'To rename it', 'To let an outer handler complete the handling', 'D', 'Re-throwing lets lower code do local cleanup while higher code performs the full response.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why re-throw an exception after partially handling it?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is exception chaining?', 'Wrapping a caught exception as the cause of a new one', 'Catching twice', 'Throwing in finally', 'Ignoring exceptions', 'A', 'Chaining attaches the original exception as the cause, preserving the root problem''s context.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is exception chaining?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What should a finally block typically contain?', 'Business logic only', 'Resource cleanup such as closing files', 'A throw for every case', 'The main computation', 'B', 'finally is ideal for releasing resources that must be freed whether or not an error occurred.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What should a finally block typically contain?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why use a custom exception type?', 'To avoid try blocks', 'To speed up handling', 'To represent a specific error condition meaningfully', 'To delete classes', 'C', 'A custom exception conveys a domain-specific failure clearly and can be caught selectively.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why use a custom exception type?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a common pitfall of swallowing an exception with an empty catch?', 'The program speeds up', 'The catch is removed', 'Exceptions stop existing', 'Errors go unnoticed and debugging becomes hard', 'D', 'An empty catch discards error information, hiding failures and complicating debugging.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a common pitfall of swallowing an exception with an empty catch?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a try-with-resources or using construct provide?', 'Automatic resource closing at block end', 'Infinite retries', 'A new thread', 'A destructor for classes', 'A', 'Such constructs automatically release resources when the block exits, even on exceptions.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a try-with-resources or using construct provide?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why order catch blocks from most specific to most general?', 'Order never matters', 'A general handler first would intercept specific exceptions', 'Specific types cannot be caught', 'General types are illegal', 'B', 'If a broad catch comes first it handles everything, so more specific handlers must precede it.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why order catch blocks from most specific to most general?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What information does an exception object usually carry?', 'The entire program source', 'A loop counter', 'A message and often a stack trace', 'The class file', 'C', 'Exception objects typically include a descriptive message and the call stack where it was thrown.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What information does an exception object usually carry?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'When is throwing an exception preferable to returning an error code?', 'When failures are routine and expected', 'When performance is the only concern', 'When there is no error', 'When callers must not ignore the failure', 'D', 'Exceptions make failures hard to ignore and separate error handling from normal flow.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'When is throwing an exception preferable to returning an error code?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does rethrowing without catching (propagation) rely on?', 'The runtime unwinding the stack to find a handler', 'A loop', 'A constructor', 'A static field', 'A', 'Propagation lets the runtime walk up the call stack until a matching handler is found.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does rethrowing without catching (propagation) rely on?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why avoid using exceptions for ordinary control flow?', 'They are faster than branches', 'They are costlier and obscure normal logic', 'They cannot be caught', 'They replace all loops', 'B', 'Exceptions carry overhead and reduce clarity when used for expected, routine control flow.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why avoid using exceptions for ordinary control flow?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the role of the exception type in matching a catch?', 'It matches any message', 'It matches by line number', 'A catch handles exceptions of its type or subtypes', 'It matches randomly', 'C', 'A catch clause handles exceptions whose type is the declared type or a subtype of it.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the role of the exception type in matching a catch?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a finally block do if the try block already returned a value?', 'It is skipped', 'It cancels the return', 'It throws automatically', 'It still runs before control leaves the method', 'D', 'finally executes even after a return, running cleanup before the method actually returns.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a finally block do if the try block already returned a value?');

  -- ---- Data Structures and Algorithms / Arrays and Linked Lists (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Data Structures and Algorithms'
    and t.topic_name = 'Arrays and Linked Lists';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Data Structures and Algorithms', 'Arrays and Linked Lists';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the time complexity of accessing an element by index in an array?', 'O(1)', 'O(n)', 'O(log n)', 'O(n^2)', 'A', 'Contiguous storage lets an array compute an element''s address directly, giving constant-time access.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the time complexity of accessing an element by index in an array?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is inserting at the head of a singly linked list O(1)?', 'All nodes shift', 'Only a few pointers are updated', 'The list is re-sorted', 'It copies the array', 'B', 'Head insertion creates a node and relinks the head pointer, independent of list length.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is inserting at the head of a singly linked list O(1)?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a node in a singly linked list contain?', 'Data and an index', 'Two pointers always', 'Data and a pointer to the next node', 'Only data', 'C', 'A singly linked node holds its value and a reference to the following node.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a node in a singly linked list contain?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does accessing the k-th element of a linked list take O(k)?', 'Nodes are indexed directly', 'The list is contiguous', 'It uses binary search', 'You must traverse from the head node by node', 'D', 'Without index arithmetic, reaching position k requires following k links from the head.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does accessing the k-th element of a linked list take O(k)?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What advantage does a dynamic array offer over a fixed array?', 'It can grow by reallocating when full', 'It never uses extra memory', 'It cannot be indexed', 'It stores only pointers', 'A', 'A dynamic array resizes by allocating a larger buffer and copying elements when capacity is exceeded.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What advantage does a dynamic array offer over a fixed array?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is amortized O(1) append in a dynamic array due to?', 'Appends never copy', 'Occasional doubling spreads the copy cost over many appends', 'Each append reallocates', 'Arrays cannot append', 'B', 'Growth by doubling makes the rare costly resize average out to constant time per append.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is amortized O(1) append in a dynamic array due to?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What extra pointer does a node in a doubly linked list have?', 'A pointer to the head', 'An index field', 'A pointer to the previous node', 'A hash value', 'C', 'A doubly linked node stores both next and previous pointers, allowing backward traversal.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What extra pointer does a node in a doubly linked list have?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can deleting a known node be O(1) in a doubly linked list?', 'The list must be searched', 'Arrays are faster', 'All nodes shift', 'Both neighbors are directly reachable to relink', 'D', 'With previous and next pointers available, the node''s neighbors can be relinked without traversal.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can deleting a known node be O(1) in a doubly linked list?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a disadvantage of linked lists compared with arrays?', 'Poor cache locality and no O(1) random access', 'They cannot store data', 'They waste no memory', 'They are always slower to insert at head', 'A', 'Scattered nodes hurt cache performance, and reaching an arbitrary position needs traversal.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a disadvantage of linked lists compared with arrays?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an array''s contiguous memory layout help with?', 'Constant-time head insertion', 'Cache-friendly sequential access', 'Avoiding all copies', 'Unlimited growth', 'B', 'Because elements sit together in memory, sequential scans benefit from cache prefetching.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an array''s contiguous memory layout help with?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens when you insert into the middle of an array of size n?', 'It is always O(1)', 'The array shrinks', 'Subsequent elements shift, costing O(n)', 'Only the first element moves', 'C', 'Making room in the middle requires shifting the following elements, which is linear work.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens when you insert into the middle of an array of size n?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a circular linked list?', 'A list with no nodes', 'A sorted array', 'A list with two heads', 'A list whose last node points back to the first', 'D', 'In a circular linked list the tail''s next pointer references the head, forming a cycle.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a circular linked list?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why might you choose a linked list for a queue implementation?', 'O(1) insertion and removal at the ends', 'O(1) random access', 'Smaller memory per element', 'Better cache behavior', 'A', 'A linked list supports constant-time enqueue and dequeue at its ends without shifting.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why might you choose a linked list for a queue implementation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the head pointer of a linked list reference?', 'The last node always', 'The first node, or null if empty', 'A random node', 'The array length', 'B', 'The head points to the first node; an empty list has a null head.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the head pointer of a linked list reference?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How much extra space per element does a linked list use compared with an array?', 'No extra space', 'Exactly double the data', 'Space for one or more pointers', 'The whole array again', 'C', 'Each node stores pointers in addition to its data, which arrays do not require.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How much extra space per element does a linked list use compared with an array?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is required to search for a value in an unsorted array?', 'A single index computation', 'Binary search', 'A hash lookup', 'A linear scan of up to n elements', 'D', 'Unsorted data has no shortcut, so finding a value may require examining every element.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is required to search for a value in an unsorted array?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is reversing a singly linked list typically O(n)?', 'Each node''s next pointer must be flipped once', 'It copies to an array first', 'It is O(1)', 'Nodes are indexed', 'A', 'Reversal walks the list once, redirecting each node''s pointer, which is linear in the node count.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is reversing a singly linked list typically O(n)?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What problem does a dangling pointer in a linked list cause?', 'Faster traversal', 'A reference to freed or invalid memory', 'Automatic sorting', 'Extra cache hits', 'B', 'A dangling pointer refers to a node that has been freed, leading to undefined behavior if used.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What problem does a dangling pointer in a linked list cause?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the benefit of storing a tail pointer in a linked list?', 'O(1) random access', 'Less memory per node', 'O(1) append at the end', 'Automatic sorting', 'C', 'A tail pointer lets you append to the end without traversing the whole list.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the benefit of storing a tail pointer in a linked list?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which structure better supports frequent indexed reads of random positions?', 'A singly linked list', 'A doubly linked list', 'A circular list', 'An array', 'D', 'Arrays give constant-time indexed access, which linked lists cannot match.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which structure better supports frequent indexed reads of random positions?');

  -- ---- Data Structures and Algorithms / Stacks and Queues (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Data Structures and Algorithms'
    and t.topic_name = 'Stacks and Queues';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Data Structures and Algorithms', 'Stacks and Queues';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What ordering discipline does a stack follow?', 'Last-in, first-out', 'First-in, first-out', 'Random order', 'Sorted order', 'A', 'A stack removes the most recently added item first, which is last-in, first-out (LIFO).', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What ordering discipline does a stack follow?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What ordering discipline does a queue follow?', 'Last-in, first-out', 'First-in, first-out', 'Priority order', 'Reverse order', 'B', 'A queue removes the earliest added item first, which is first-in, first-out (FIFO).', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What ordering discipline does a queue follow?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which pair of operations defines a stack?', 'enqueue and dequeue', 'insert and index', 'push and pop', 'peek and sort', 'C', 'A stack adds with push and removes with pop from the same end, the top.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which pair of operations defines a stack?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which pair of operations defines a queue?', 'push and pop at one end', 'insert and delete by index', 'sort and search', 'enqueue and dequeue', 'D', 'A queue adds at the rear with enqueue and removes from the front with dequeue.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which pair of operations defines a queue?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is a stack natural for evaluating balanced parentheses?', 'The most recent opener must match the next closer', 'Parentheses are sorted', 'Queues cannot store symbols', 'It uses random access', 'A', 'Matching brackets is LIFO: the latest unmatched opener pairs with the next closer, which a stack tracks.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is a stack natural for evaluating balanced parentheses?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the peek operation do on a stack?', 'Removes the bottom element', 'Returns the top element without removing it', 'Clears the stack', 'Reverses the stack', 'B', 'Peek inspects the top element while leaving the stack unchanged.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the peek operation do on a stack?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a common use of a stack in program execution?', 'Scheduling print jobs', 'Breadth-first traversal', 'Tracking function call frames', 'Round-robin scheduling', 'C', 'The call stack stores return addresses and locals for active function calls in LIFO order.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a common use of a stack in program execution?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a circular buffer used to implement efficiently?', 'A sorted array', 'A recursion stack', 'A hash table', 'A fixed-capacity queue', 'D', 'A circular buffer reuses a fixed array with wraparound indices to implement a bounded queue.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a circular buffer used to implement efficiently?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can a queue be implemented with two stacks?', 'Reversing with a second stack yields FIFO order', 'Stacks are already FIFO', 'Queues cannot be built', 'It needs an array', 'A', 'Transferring elements between two stacks reverses order twice overall, producing queue behavior.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can a queue be implemented with two stacks?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens when you pop from an empty stack?', 'It returns the first inserted item', 'It is an underflow error or special result', 'It doubles capacity', 'It sorts the stack', 'B', 'Popping an empty stack has nothing to remove, so it signals underflow or returns a sentinel.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens when you pop from an empty stack?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a priority queue?', 'A stack with two tops', 'A sorted array only', 'A queue where highest-priority elements are served first', 'A FIFO queue', 'C', 'A priority queue dequeues the element with the highest priority rather than the earliest inserted.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a priority queue?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which traversal of a graph naturally uses a queue?', 'Depth-first search with recursion', 'Binary search', 'In-order traversal', 'Breadth-first search', 'D', 'BFS explores level by level, enqueuing neighbors, which fits a FIFO queue.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which traversal of a graph naturally uses a queue?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which traversal naturally uses a stack (or recursion)?', 'Depth-first search', 'Breadth-first search', 'Level-order traversal', 'Round-robin', 'A', 'DFS dives deep before backtracking, matching the LIFO behavior of a stack or the call stack.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which traversal naturally uses a stack (or recursion)?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the front of a queue refer to?', 'The most recently added element', 'The element that will be removed next', 'The middle element', 'A random element', 'B', 'The front holds the earliest inserted element, which the next dequeue removes.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the front of a queue refer to?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does an array-backed stack usually give O(1) push and pop?', 'Elements are sorted each time', 'The array is copied each push', 'Operations occur at one end without shifting', 'It searches for the top', 'C', 'Working only at the top avoids shifting elements, so push and pop are constant time (amortized).', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does an array-backed stack usually give O(1) push and pop?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a deque?', 'A sorted stack', 'A single-ended queue only', 'A hash set', 'A double-ended queue allowing operations at both ends', 'D', 'A deque supports insertion and removal at both the front and the back.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a deque?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does an undo feature typically use a stack?', 'Recent actions are pushed and popped to reverse them', 'Actions are enqueued in order', 'Actions are sorted alphabetically', 'Actions are hashed', 'A', 'Undo reverses the most recent action first, which is naturally LIFO.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does an undo feature typically use a stack?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What causes stack overflow in recursion?', 'Too few calls', 'Too many nested calls exceed the stack''s capacity', 'An empty queue', 'A sorted input', 'B', 'Each call consumes stack space; excessive recursion depth exhausts the available stack.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What causes stack overflow in recursion?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the result of enqueuing 1,2,3 then dequeuing once?', '3 is removed', '2 is removed', '1 is removed, leaving 2 and 3', 'The queue is cleared', 'C', 'FIFO removes the earliest element, 1, leaving 2 and 3 in order.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the result of enqueuing 1,2,3 then dequeuing once?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is a bounded queue useful in producer-consumer systems?', 'It has unlimited capacity', 'It sorts items', 'It removes the oldest randomly', 'It limits buffering and applies backpressure', 'D', 'A bounded queue caps buffered work, naturally throttling producers when consumers lag.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is a bounded queue useful in producer-consumer systems?');

  -- ---- Data Structures and Algorithms / Trees (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Data Structures and Algorithms'
    and t.topic_name = 'Trees';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Data Structures and Algorithms', 'Trees';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What defines a binary tree?', 'Each node has at most two children', 'Each node has exactly three children', 'Nodes form a cycle', 'All nodes are leaves', 'A', 'In a binary tree every node has no more than two children, typically called left and right.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What defines a binary tree?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What property holds in a binary search tree?', 'All keys are equal', 'Left subtree keys are smaller and right subtree keys are larger', 'It is unordered', 'Only leaves hold keys', 'B', 'A BST keeps smaller keys to the left and larger keys to the right of each node.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What property holds in a binary search tree?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the height of a tree?', 'The number of leaves', 'The count of all nodes', 'The longest path length from root to a leaf', 'The root''s value', 'C', 'Height is the number of edges on the longest root-to-leaf path.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the height of a tree?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can search in a balanced BST be O(log n)?', 'It scans every node', 'Trees are arrays', 'It uses hashing', 'Each comparison discards about half the remaining nodes', 'D', 'A balanced BST halves the search space at each step, giving logarithmic search time.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can search in a balanced BST be O(log n)?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an in-order traversal of a BST produce?', 'Keys in sorted ascending order', 'Keys in random order', 'Only leaf keys', 'Keys in reverse insertion order', 'A', 'Visiting left, node, then right yields the BST''s keys in ascending sorted order.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an in-order traversal of a BST produce?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a leaf node?', 'The root node', 'A node with no children', 'A node with two children', 'An empty tree', 'B', 'A leaf has no children and sits at the bottom of its path.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a leaf node?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can an unbalanced BST degrade to O(n) operations?', 'It always stays balanced', 'It becomes a hash table', 'It can become a long chain like a linked list', 'It loses its keys', 'C', 'Inserting sorted data can make a BST a chain, so operations become linear.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can an unbalanced BST degrade to O(n) operations?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What problem do self-balancing trees like AVL or red-black trees solve?', 'Removing all keys', 'Converting to arrays', 'Eliminating comparisons', 'Keeping height logarithmic to bound operation cost', 'D', 'Self-balancing trees restructure on updates to keep height near log n, bounding operation time.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What problem do self-balancing trees like AVL or red-black trees solve?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a complete binary tree?', 'All levels filled except possibly the last, filled left to right', 'A tree with one node', 'A tree with no leaves', 'An unordered tree', 'A', 'A complete binary tree fills every level fully except the last, which fills from the left.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a complete binary tree?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What traversal visits the root before its subtrees?', 'In-order', 'Pre-order', 'Post-order', 'Level-order from leaves', 'B', 'Pre-order visits the node first, then recurses into left and right subtrees.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What traversal visits the root before its subtrees?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What traversal visits a node after both its subtrees?', 'Pre-order', 'In-order', 'Post-order', 'Reverse level-order', 'C', 'Post-order processes left and right subtrees before visiting the node, useful for deletion.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What traversal visits a node after both its subtrees?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What structure is a binary heap?', 'A binary search tree', 'A linked list', 'A hash table', 'A complete tree satisfying a heap order property', 'D', 'A binary heap is a complete binary tree where each parent satisfies an order relation with its children.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What structure is a binary heap?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is a binary heap often stored in an array?', 'Parent and child indices are computed arithmetically', 'Arrays sort automatically', 'It avoids all comparisons', 'Heaps cannot use pointers', 'A', 'In a complete tree, index math (2i+1, 2i+2) locates children, so an array stores the heap compactly.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is a binary heap often stored in an array?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the time to find the minimum in a min-heap?', 'O(n)', 'O(1) at the root', 'O(log n)', 'O(n log n)', 'B', 'A min-heap keeps the smallest element at the root, so reading the minimum is constant time.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the time to find the minimum in a min-heap?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does inserting into a BST do when the key is larger than the current node?', 'Recurse into the left subtree', 'Replace the root', 'Recurse into the right subtree', 'Delete the node', 'C', 'Larger keys belong to the right, so insertion continues down the right subtree.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does inserting into a BST do when the key is larger than the current node?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a subtree?', 'A single edge', 'The root only', 'A disconnected node', 'A node together with all its descendants', 'D', 'A subtree consists of a node and every node reachable beneath it.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a subtree?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is level-order traversal implemented with a queue?', 'Nodes are visited breadth-first level by level', 'It uses recursion only', 'It sorts the tree', 'It visits leaves first', 'A', 'Level-order explores nodes level by level, enqueuing children, which a FIFO queue manages.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is level-order traversal implemented with a queue?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does deleting a node with two children in a BST typically require?', 'Removing the whole subtree', 'Replacing it with its in-order successor or predecessor', 'Converting to a heap', 'Nothing special', 'B', 'To preserve order, the node is replaced by its in-order successor or predecessor, which is then removed.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does deleting a node with two children in a BST typically require?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the maximum number of nodes in a binary tree of height h (edges)?', 'h', '2h', '2^(h+1) - 1', 'h^2', 'C', 'A perfect binary tree of height h has 2^(h+1) - 1 nodes across its levels.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the maximum number of nodes in a binary tree of height h (edges)?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which application fits a tree structure well?', 'A simple FIFO buffer', 'A flat list of equal items', 'A single counter', 'Representing a file system hierarchy', 'D', 'Hierarchical data such as directories and files maps naturally onto a tree.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which application fits a tree structure well?');

  -- ---- Data Structures and Algorithms / Graphs (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Data Structures and Algorithms'
    and t.topic_name = 'Graphs';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Data Structures and Algorithms', 'Graphs';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What are the two basic components of a graph?', 'Vertices and edges', 'Rows and columns', 'Keys and values', 'Nodes and leaves only', 'A', 'A graph consists of vertices (nodes) connected by edges (links).', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What are the two basic components of a graph?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What distinguishes a directed graph from an undirected one?', 'Directed graphs have no edges', 'Edges have a direction in a directed graph', 'Undirected graphs are always cyclic', 'They are identical', 'B', 'In a directed graph each edge points from one vertex to another; undirected edges have no direction.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What distinguishes a directed graph from an undirected one?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an adjacency matrix store?', 'Only vertex labels', 'The shortest paths', 'Whether an edge exists between each pair of vertices', 'A sorted edge list', 'C', 'An adjacency matrix uses a grid where each cell marks the presence or weight of an edge.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an adjacency matrix store?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is an adjacency list often preferred for sparse graphs?', 'It stores every possible edge', 'It is always faster to query any pair', 'It cannot represent edges', 'It stores only existing edges, saving space', 'D', 'Sparse graphs have few edges, so listing only actual neighbors uses far less space than a full matrix.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is an adjacency list often preferred for sparse graphs?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which traversal explores a graph level by level from a source?', 'Breadth-first search', 'Depth-first search', 'Binary search', 'In-order traversal', 'A', 'BFS visits all neighbors at the current distance before moving outward, using a queue.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which traversal explores a graph level by level from a source?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What data structure does iterative depth-first search typically use?', 'A queue', 'A stack', 'A heap', 'A hash map only', 'B', 'DFS dives deep and backtracks, which matches a stack (or recursion using the call stack).', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What data structure does iterative depth-first search typically use?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a cycle in a graph mean?', 'A single edge', 'An isolated vertex', 'A path that returns to a starting vertex', 'A sorted order', 'C', 'A cycle is a path that begins and ends at the same vertex without repeating edges.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a cycle in a graph mean?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does Dijkstra''s algorithm require non-negative edge weights?', 'It cannot read weights', 'Weights must be integers', 'It only works on trees', 'Negative weights can invalidate its greedy choices', 'D', 'Dijkstra assumes that once a vertex is finalized its distance is optimal, which negative edges can break.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does Dijkstra''s algorithm require non-negative edge weights?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a topological sort order?', 'Vertices of a DAG so edges go from earlier to later', 'Vertices of any cyclic graph', 'Edges by weight', 'Vertices alphabetically', 'A', 'Topological sort linearly orders a directed acyclic graph so every edge points forward.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a topological sort order?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a connected component in an undirected graph?', 'A single edge', 'A maximal set of mutually reachable vertices', 'The vertex with most edges', 'A sorted path', 'B', 'A connected component is a maximal group of vertices where each pair is connected by some path.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a connected component in an undirected graph?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the degree of a vertex measure?', 'Its distance from the root', 'Its label value', 'The number of edges incident to it', 'The graph size', 'C', 'A vertex''s degree counts the edges touching it; directed graphs split this into in-degree and out-degree.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the degree of a vertex measure?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can BFS find the shortest path in an unweighted graph?', 'It uses edge weights', 'It sorts vertices', 'It uses recursion only', 'It reaches each vertex by the fewest edges first', 'D', 'BFS expands by distance, so it first reaches each vertex via the minimum number of edges.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can BFS find the shortest path in an unweighted graph?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a weighted graph?', 'A graph whose edges carry numeric costs', 'A graph with no edges', 'A graph of equal edges', 'A tree only', 'A', 'In a weighted graph each edge has an associated cost or weight used by many algorithms.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a weighted graph?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a minimum spanning tree connect?', 'Only two vertices', 'All vertices with minimum total edge weight and no cycle', 'The heaviest edges', 'A single component''s root', 'B', 'An MST connects every vertex using edges of least total weight while remaining acyclic.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a minimum spanning tree connect?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why might DFS be used to detect a cycle in a directed graph?', 'It sorts the edges', 'It counts vertices', 'Revisiting a vertex on the current path indicates a cycle', 'It finds shortest paths', 'C', 'If DFS encounters a vertex already on the active recursion path, a cycle exists.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why might DFS be used to detect a cycle in a directed graph?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a self-loop?', 'An edge between two vertices', 'A disconnected vertex', 'A sorted path', 'An edge from a vertex to itself', 'D', 'A self-loop is an edge whose endpoints are the same vertex.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a self-loop?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an adjacency matrix cost in space for n vertices?', 'O(n^2)', 'O(n)', 'O(log n)', 'O(1)', 'A', 'A full matrix stores an entry for every vertex pair, requiring space proportional to n squared.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an adjacency matrix cost in space for n vertices?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How do you represent that two vertices are neighbors in an adjacency list?', 'A single global counter', 'Each vertex stores a list of its adjacent vertices', 'A sorted matrix row', 'A hash of the whole graph', 'B', 'In an adjacency list, each vertex keeps a collection of the vertices it connects to.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How do you represent that two vertices are neighbors in an adjacency list?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a bipartite graph?', 'A graph with one vertex', 'A fully connected graph', 'Vertices split into two sets with edges only between sets', 'A tree with cycles', 'C', 'A bipartite graph partitions vertices into two groups so every edge joins the two groups.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a bipartite graph?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which real-world problem maps naturally to a graph?', 'Storing a single value', 'Looping a fixed number of times', 'Formatting text', 'Finding routes in a road network', 'D', 'Road networks have intersections (vertices) and roads (edges), a natural graph.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which real-world problem maps naturally to a graph?');

  -- ---- Data Structures and Algorithms / Sorting Algorithms (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Data Structures and Algorithms'
    and t.topic_name = 'Sorting Algorithms';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Data Structures and Algorithms', 'Sorting Algorithms';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the average time complexity of quicksort?', 'O(n log n)', 'O(n)', 'O(n^2)', 'O(log n)', 'A', 'Quicksort partitions around a pivot and recurses, averaging O(n log n) comparisons.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the average time complexity of quicksort?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can quicksort degrade to O(n^2)?', 'It always balances', 'Poor pivot choices create very unbalanced partitions', 'It uses no comparisons', 'Input is always sorted', 'B', 'If the pivot repeatedly splits off only one element, the recursion depth and work become quadratic.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can quicksort degrade to O(n^2)?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What makes a sort stable?', 'It never swaps', 'It uses no extra memory', 'Equal keys keep their original relative order', 'It is always fastest', 'C', 'A stable sort preserves the input order of elements that compare equal.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What makes a sort stable?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the worst-case time complexity of merge sort?', 'O(n^2)', 'O(n)', 'O(log n)', 'O(n log n)', 'D', 'Merge sort always divides in half and merges linearly, giving O(n log n) in all cases.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the worst-case time complexity of merge sort?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What extra resource does classic merge sort require?', 'O(n) auxiliary space for merging', 'No extra space', 'O(n^2) space', 'A hash table', 'A', 'Merging typically uses an auxiliary array of size proportional to n.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What extra resource does classic merge sort require?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does bubble sort move elements?', 'By partitioning around a pivot', 'By repeatedly swapping adjacent out-of-order pairs', 'By merging halves', 'By using a heap', 'B', 'Bubble sort compares neighbors and swaps them until the list is ordered.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does bubble sort move elements?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the time complexity of insertion sort on nearly sorted data?', 'Always O(n^2)', 'O(n log n)', 'Close to O(n)', 'O(log n)', 'C', 'Insertion sort does little work when few elements are out of place, approaching linear time.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the time complexity of insertion sort on nearly sorted data?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does selection sort do on each pass?', 'Partition around a pivot', 'Merge two halves', 'Build a heap', 'Select the smallest remaining element and place it', 'D', 'Selection sort repeatedly finds the minimum of the unsorted part and moves it into place.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does selection sort do on each pass?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is heap sort O(n log n)?', 'Each of n extractions costs O(log n) to re-heapify', 'It merges halves', 'It scans once', 'It partitions linearly', 'A', 'Heap sort builds a heap then extracts the root n times, each extraction costing log n.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is heap sort O(n log n)?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What property lets counting sort beat the O(n log n) comparison bound?', 'It compares every pair', 'It uses key values as indices instead of comparing', 'It merges sublists', 'It picks random pivots', 'B', 'Counting sort tallies occurrences by key, avoiding comparisons, so it can run in linear time for small key ranges.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What property lets counting sort beat the O(n log n) comparison bound?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the lower bound for comparison-based sorting?', 'O(n)', 'O(log n)', 'O(n log n)', 'O(1)', 'C', 'Any sort that only compares elements needs at least on the order of n log n comparisons in the worst case.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the lower bound for comparison-based sorting?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the partition step in quicksort produce?', 'A fully sorted array', 'A merged list', 'A heap', 'Elements less than the pivot on one side and greater on the other', 'D', 'Partitioning arranges elements relative to the pivot, which then sits in its final position.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the partition step in quicksort produce?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is merge sort a good choice for linked lists?', 'It merges without needing random access', 'It requires indexing', 'It is in-place on arrays only', 'It cannot sort lists', 'A', 'Merge sort processes elements sequentially, which suits linked lists that lack cheap random access.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is merge sort a good choice for linked lists?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is an in-place sort?', 'One that doubles the array', 'One that uses only a small, constant amount of extra space', 'One that needs O(n) buffers', 'One that cannot swap', 'B', 'An in-place sort rearranges elements within the input using O(1) extra space.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is an in-place sort?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does choosing a median-of-three pivot aim to reduce?', 'The number of elements', 'The need to compare', 'The chance of worst-case quicksort partitions', 'The array size', 'C', 'Median-of-three picks a better pivot, making badly unbalanced partitions less likely.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does choosing a median-of-three pivot aim to reduce?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which sort is typically fastest in practice for large random arrays?', 'Bubble sort', 'Selection sort', 'Insertion sort', 'Quicksort', 'D', 'Quicksort''s good cache behavior and low constants make it fast on large random data on average.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which sort is typically fastest in practice for large random arrays?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does radix sort process?', 'Keys digit by digit from least or most significant', 'Random pivots', 'Merged halves', 'Heap roots', 'A', 'Radix sort distributes keys by individual digits across passes, often using a stable counting sort.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does radix sort process?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is bubble sort rarely used in practice?', 'It is unstable', 'Its O(n^2) comparisons make it slow on large inputs', 'It needs O(n) extra space', 'It cannot sort integers', 'B', 'Bubble sort''s quadratic time makes it inefficient compared with O(n log n) sorts.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is bubble sort rarely used in practice?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a stable sort help preserve when sorting records by one field?', 'The reverse order', 'A random order', 'The prior ordering of records with equal keys', 'Only the first record', 'C', 'Stability keeps equal-key records in their earlier order, useful for multi-key sorting.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a stable sort help preserve when sorting records by one field?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the best-case time of quicksort with balanced partitions?', 'O(n^2)', 'O(n)', 'O(log n)', 'O(n log n)', 'D', 'Balanced partitions give log n recursion depth with linear work per level, so O(n log n).', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the best-case time of quicksort with balanced partitions?');

  -- ---- Data Structures and Algorithms / Searching Algorithms (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Data Structures and Algorithms'
    and t.topic_name = 'Searching Algorithms';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Data Structures and Algorithms', 'Searching Algorithms';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the time complexity of linear search in the worst case?', 'O(n)', 'O(log n)', 'O(1)', 'O(n log n)', 'A', 'Linear search may examine every element, so the worst case is proportional to n.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the time complexity of linear search in the worst case?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What precondition does binary search require?', 'The collection must be a linked list', 'The collection must be sorted', 'Elements must be unique', 'The size must be a power of two', 'B', 'Binary search relies on order to discard half the range each step, so the data must be sorted.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What precondition does binary search require?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the time complexity of binary search?', 'O(n)', 'O(n log n)', 'O(log n)', 'O(1)', 'C', 'Each comparison halves the search space, giving logarithmic time.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the time complexity of binary search?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does binary search do when the middle element is less than the target?', 'Search the left half', 'Stop and fail', 'Restart from the beginning', 'Search the right half', 'D', 'If the middle is too small, the target must lie in the larger right half.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does binary search do when the middle element is less than the target?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is hashing able to offer average O(1) lookup?', 'A hash function maps keys directly to buckets', 'It sorts the keys first', 'It scans all elements', 'It uses binary search', 'A', 'Hashing computes a bucket index from the key, allowing direct access on average.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is hashing able to offer average O(1) lookup?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What degrades hash table lookup toward O(n)?', 'An empty table', 'Many collisions concentrating keys in few buckets', 'A perfect hash', 'Too few keys', 'B', 'Heavy collisions create long chains or probe sequences, lengthening lookups toward linear time.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What degrades hash table lookup toward O(n)?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an unsuccessful binary search ultimately detect?', 'The array doubles', 'The first element matches', 'The search range becomes empty', 'A collision occurs', 'C', 'When the low and high bounds cross, the range is empty and the target is absent.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an unsuccessful binary search ultimately detect?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'When is linear search preferable to binary search?', 'On large sorted data', 'When O(log n) is required', 'On a balanced BST', 'On small or unsorted data', 'D', 'For small or unsorted collections, linear search avoids the cost or precondition of sorting.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'When is linear search preferable to binary search?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is interpolation search best suited for?', 'Uniformly distributed sorted numeric keys', 'Unsorted data', 'Linked lists', 'Random hash tables', 'A', 'Interpolation search estimates the position by value and excels on evenly distributed sorted keys.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is interpolation search best suited for?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the midpoint calculation low + (high - low) / 2 avoid compared with (low + high) / 2?', 'A slower loop', 'Integer overflow for large indices', 'Using recursion', 'Sorting the array', 'B', 'Computing the offset from low prevents the sum of two large indices from overflowing.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the midpoint calculation low + (high - low) / 2 avoid compared with (low + high) / 2?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What search technique repeatedly doubles the index to find a range, then binary searches?', 'Bubble search', 'Hash search', 'Exponential search', 'Depth-first search', 'C', 'Exponential search finds a bound by doubling, then binary searches within that range.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What search technique repeatedly doubles the index to find a range, then binary searches?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does searching a balanced BST take O(log n)?', 'It scans all nodes', 'It uses hashing', 'It sorts first', 'Each comparison moves to one subtree, halving the nodes', 'D', 'A balanced BST discards roughly half the remaining nodes per comparison.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does searching a balanced BST take O(log n)?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a successful binary search return?', 'The index of the matching element', 'The array length', 'The first element', 'A hash value', 'A', 'On a match, binary search reports the position where the target was found.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a successful binary search return?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a hash collision?', 'A key with no value', 'Two keys mapping to the same bucket', 'An empty table', 'A sorted key', 'B', 'A collision occurs when distinct keys hash to the same index and must share a bucket strategy.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a hash collision?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which collision-resolution method stores colliding entries in a list per bucket?', 'Linear probing', 'Binary search', 'Separate chaining', 'Interpolation', 'C', 'Separate chaining keeps a list (or similar) at each bucket to hold multiple colliding keys.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which collision-resolution method stores colliding entries in a list per bucket?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is open addressing in hashing?', 'Chaining into lists', 'Sorting keys', 'Rehashing all data each insert', 'Probing other buckets to place a colliding key', 'D', 'Open addressing resolves collisions by probing to find another open slot within the table.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is open addressing in hashing?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why keep a hash table''s load factor low?', 'To limit collisions and keep operations fast', 'To use more memory always', 'To avoid storing keys', 'To force O(n) lookups', 'A', 'A low load factor reduces collisions, keeping average operations near constant time.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why keep a hash table''s load factor low?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does linear search examine first?', 'The middle element', 'The elements in order from the start', 'A hashed bucket', 'The last element only', 'B', 'Linear search inspects elements sequentially beginning at the first position.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does linear search examine first?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the benefit of a sorted array for repeated searches?', 'It cannot be searched', 'Lookups become O(n)', 'Binary search gives fast O(log n) lookups', 'It prevents duplicates', 'C', 'Once sorted, an array supports repeated logarithmic-time binary searches.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the benefit of a sorted array for repeated searches?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What search strategy is used by a dictionary or map keyed by strings?', 'Bubble search', 'Topological search', 'Breadth-first search', 'Hash-based lookup', 'D', 'Hash maps compute a hash of the key to locate its value quickly.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What search strategy is used by a dictionary or map keyed by strings?');

  -- ---- Data Structures and Algorithms / Algorithm Complexity (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Data Structures and Algorithms'
    and t.topic_name = 'Algorithm Complexity';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Data Structures and Algorithms', 'Algorithm Complexity';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does Big-O notation describe?', 'An upper bound on growth as input size increases', 'Exact running time in seconds', 'Memory addresses', 'The number of lines of code', 'A', 'Big-O expresses how an algorithm''s cost grows with input size, ignoring constants and lower terms.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does Big-O notation describe?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which growth rate is fastest-growing among these?', 'O(n log n)', 'O(n^2)', 'O(n)', 'O(log n)', 'B', 'Quadratic growth outpaces linearithmic, linear, and logarithmic growth for large n.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which growth rate is fastest-growing among these?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the complexity of a loop nested inside another loop over n elements?', 'O(n)', 'O(log n)', 'O(n^2)', 'O(1)', 'C', 'Each of n outer iterations runs n inner iterations, giving n times n operations.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the complexity of a loop nested inside another loop over n elements?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why are constant factors dropped in Big-O?', 'Constants are always one', 'They are illegal to count', 'They change the input size', 'It describes asymptotic growth, not exact counts', 'D', 'Big-O focuses on how cost scales, so constant multipliers are omitted.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why are constant factors dropped in Big-O?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does O(1) describe?', 'Constant time independent of input size', 'Linear time', 'Logarithmic time', 'Exponential time', 'A', 'An O(1) operation takes the same time regardless of how large the input is.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does O(1) describe?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which best describes O(log n) behavior?', 'Cost doubles with each element', 'Cost grows slowly as the problem is repeatedly halved', 'Cost is constant', 'Cost grows quadratically', 'B', 'Logarithmic cost arises when each step reduces the problem by a constant factor, such as halving.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which best describes O(log n) behavior?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the difference between worst-case and average-case complexity?', 'They are identical', 'Average-case is always larger', 'Worst-case bounds the slowest input; average-case considers typical inputs', 'Worst-case ignores input', 'C', 'Worst-case describes the hardest input, while average-case reflects expected behavior over inputs.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the difference between worst-case and average-case complexity?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does space complexity measure?', 'Time taken', 'Number of comparisons', 'Disk speed', 'Memory used relative to input size', 'D', 'Space complexity expresses how memory consumption grows with input size.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does space complexity measure?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can an O(n) algorithm beat an O(log n) one for small inputs?', 'Constant factors and overhead can dominate at small n', 'O(n) is always faster', 'Big-O guarantees runtime', 'log n grows faster', 'A', 'Asymptotic order ignores constants, so for small inputs a higher-order algorithm may run faster.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can an O(n) algorithm beat an O(log n) one for small inputs?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is amortized analysis used for?', 'Measuring a single worst operation only', 'Averaging the cost of operations over a sequence', 'Counting memory addresses', 'Timing one run', 'B', 'Amortized analysis spreads occasional expensive operations over many cheap ones to find an average cost.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is amortized analysis used for?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does O(n log n) commonly characterize?', 'Simple array indexing', 'A single comparison', 'Efficient comparison-based sorting', 'Exponential search', 'C', 'Good general-purpose sorts like merge sort and heap sort run in O(n log n).', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does O(n log n) commonly characterize?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What growth does doubling the input cause for an O(n) algorithm?', 'Four times the work', 'No change', 'Half the work', 'Roughly double the work', 'D', 'Linear cost scales directly with input, so doubling n roughly doubles the work.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What growth does doubling the input cause for an O(n) algorithm?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'For a quadratic O(n^2) algorithm, how does cost change when its data size grows tenfold?', 'It rises by about a hundredfold', 'It rises tenfold', 'It stays the same', 'It falls by half', 'A', 'Quadratic cost scales with the square, so a tenfold larger size multiplies work by roughly one hundred.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'For a quadratic O(n^2) algorithm, how does cost change when its data size grows tenfold?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is Big-Omega notation?', 'An upper bound on growth', 'A lower bound on growth', 'An exact bound only', 'A memory measure', 'B', 'Big-Omega describes a lower bound, the least growth an algorithm requires.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is Big-Omega notation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does Big-Theta notation express?', 'Only an upper bound', 'Only a lower bound', 'A tight bound matching upper and lower growth', 'Exact seconds', 'C', 'Big-Theta applies when the same function bounds growth from both above and below.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does Big-Theta notation express?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which is more efficient for large n: O(n) or O(n^2)?', 'O(n^2)', 'They are equal', 'It depends on the constant only', 'O(n)', 'D', 'Linear growth is far cheaper than quadratic growth as n becomes large.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which is more efficient for large n: O(n) or O(n^2)?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an exponential O(2^n) algorithm imply for large inputs?', 'It quickly becomes impractical', 'It is always fast', 'It uses no memory', 'It is linear', 'A', 'Exponential growth makes runtime explode, so such algorithms are infeasible for large n.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an exponential O(2^n) algorithm imply for large inputs?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why analyze algorithms with Big-O rather than timing on one machine?', 'Timing is always accurate', 'It is independent of hardware and input specifics', 'Big-O gives exact seconds', 'Hardware never varies', 'B', 'Big-O characterizes scaling behavior independent of a particular machine or data set.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why analyze algorithms with Big-O rather than timing on one machine?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the complexity of accessing a hash map entry on average?', 'O(n)', 'O(log n)', 'O(1)', 'O(n log n)', 'C', 'With a good hash and low load factor, average lookup is constant time.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the complexity of accessing a hash map entry on average?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What dominates the Big-O of an expression like n^2 + 100n + 500?', 'The 500 constant', 'The 100n term', 'All equally', 'The n^2 term', 'D', 'For large n the highest-order term, n^2, dominates, so the complexity is O(n^2).', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What dominates the Big-O of an expression like n^2 + 100n + 500?');

  -- ---- Database Management Systems / Relational Model (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Database Management Systems'
    and t.topic_name = 'Relational Model';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Database Management Systems', 'Relational Model';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'In the relational model, what is a relation?', 'A table of tuples over named attributes', 'A single column', 'A stored procedure', 'A foreign key', 'A', 'A relation is a set of tuples (rows) defined over a set of named attributes (columns).', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'In the relational model, what is a relation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a tuple correspond to in a table?', 'A column', 'A row', 'A table', 'A database', 'B', 'A tuple is a single row, a set of attribute values, within a relation.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a tuple correspond to in a table?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a primary key?', 'Any column with duplicates', 'A column that can be null', 'An attribute set uniquely identifying each tuple', 'A view definition', 'C', 'A primary key uniquely identifies each row and cannot contain nulls.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a primary key?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a foreign key establish?', 'A unique index', 'A stored procedure', 'A sorting order', 'A reference from one relation to a key in another', 'D', 'A foreign key links rows by referencing the primary key (or candidate key) of another relation.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a foreign key establish?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does referential integrity require?', 'A foreign key value must match an existing referenced key or be null', 'All columns be unique', 'No null values anywhere', 'Tables be sorted', 'A', 'Referential integrity ensures foreign keys point to existing rows, preventing dangling references.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does referential integrity require?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a candidate key?', 'Any non-key column', 'A minimal attribute set that uniquely identifies tuples', 'A duplicated column', 'A view', 'B', 'A candidate key uniquely identifies rows and has no unnecessary attributes; one is chosen as primary.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a candidate key?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the degree of a relation refer to?', 'The number of tuples', 'The key length', 'The number of attributes (columns)', 'The index count', 'C', 'The degree is the count of attributes in the relation''s schema.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the degree of a relation refer to?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'A relation currently holds 500 rows; which term names that count?', 'Degree', 'Domain size', 'Key length', 'Cardinality', 'D', 'Cardinality is the number of tuples currently stored in a relation, here 500.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'A relation currently holds 500 rows; which term names that count?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does the relational model treat a relation as a set of tuples?', 'Duplicate identical rows are not meaningful in pure theory', 'Rows must be sorted', 'Columns must repeat', 'Tuples are ordered', 'A', 'In the pure model a relation is a set, so order is irrelevant and exact duplicate tuples are not distinguished.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does the relational model treat a relation as a set of tuples?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is an attribute''s domain?', 'The table name', 'The set of allowed values for that attribute', 'The primary key', 'The row count', 'B', 'A domain defines the permissible values an attribute may take, such as integers or dates.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is an attribute''s domain?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a null value represent?', 'The number zero', 'An empty string only', 'A missing or unknown value', 'A duplicate key', 'C', 'Null marks the absence of a known value, distinct from zero or an empty string.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a null value represent?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can comparisons with null yield unknown rather than true or false?', 'Null equals zero', 'Null is always true', 'Comparisons ignore null', 'Null represents unknown, so three-valued logic applies', 'D', 'SQL uses three-valued logic, so comparisons involving null produce unknown.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can comparisons with null yield unknown rather than true or false?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a superkey?', 'Any attribute set that uniquely identifies tuples', 'A minimal key only', 'A non-unique column', 'A foreign key', 'A', 'A superkey uniquely identifies rows but may include extra attributes beyond a candidate key.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a superkey?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What enforces that a primary key column has no duplicate values?', 'A foreign key', 'A uniqueness constraint on the key', 'An ordering rule', 'A default value', 'B', 'The primary key constraint enforces uniqueness (and non-nullness) across its columns.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What enforces that a primary key column has no duplicate values?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the relationship between a schema and an instance?', 'They are identical', 'Instance defines columns', 'Schema is the structure; instance is the data at a moment', 'Schema holds the rows', 'C', 'A schema defines the relation''s structure; an instance is the actual set of tuples at a given time.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the relationship between a schema and an instance?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why are relations said to have no inherent row order?', 'Rows are sorted by key', 'Order is stored on disk', 'Tuples carry positions', 'They are modeled as sets of tuples', 'D', 'Because a relation is a set, there is no guaranteed order unless a query specifies one.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why are relations said to have no inherent row order?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a composite key consist of?', 'Two or more attributes that together identify tuples', 'A single column always', 'A foreign key only', 'An index', 'A', 'A composite key uses multiple attributes jointly to uniquely identify each row.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a composite key consist of?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does projection in relational algebra do?', 'Selects specific rows', 'Selects specific columns from a relation', 'Joins two relations', 'Sorts the rows', 'B', 'Projection keeps chosen attributes and discards the others, producing a narrower relation.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does projection in relational algebra do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does selection in relational algebra do?', 'Chooses columns', 'Combines tables', 'Chooses rows satisfying a condition', 'Renames attributes', 'C', 'Selection filters tuples, keeping only those that meet a predicate.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does selection in relational algebra do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why do relational databases enforce domain constraints?', 'To sort rows', 'To create indexes', 'To remove keys', 'To keep attribute values valid and consistent', 'D', 'Domain constraints restrict values to a valid set, maintaining data integrity.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why do relational databases enforce domain constraints?');

  -- ---- Database Management Systems / SQL Fundamentals (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Database Management Systems'
    and t.topic_name = 'SQL Fundamentals';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Database Management Systems', 'SQL Fundamentals';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which SQL statement retrieves rows from a table?', 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'A', 'SELECT queries and returns rows matching the specified columns and conditions.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which SQL statement retrieves rows from a table?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the WHERE clause do in a query?', 'Chooses columns', 'Filters rows by a condition', 'Sorts the result', 'Groups rows', 'B', 'WHERE restricts the rows returned to those satisfying its predicate.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the WHERE clause do in a query?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does ORDER BY control?', 'Which columns appear', 'Row filtering', 'The sort order of the result rows', 'Grouping', 'C', 'ORDER BY arranges the result set by one or more columns, ascending or descending.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does ORDER BY control?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the INSERT statement do?', 'Removes rows', 'Changes existing rows', 'Creates a table', 'Adds new rows to a table', 'D', 'INSERT adds one or more new rows with the given column values.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the INSERT statement do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does GROUP BY enable?', 'Aggregating rows into groups for summary functions', 'Sorting rows', 'Deleting rows', 'Joining tables', 'A', 'GROUP BY collapses rows sharing values into groups so aggregates like COUNT apply per group.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does GROUP BY enable?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the role of the HAVING clause?', 'Filtering rows before grouping', 'Filtering groups after aggregation', 'Sorting results', 'Selecting columns', 'B', 'HAVING applies conditions to aggregated groups, unlike WHERE which filters individual rows.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the role of the HAVING clause?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the DISTINCT keyword do?', 'Sorts the rows', 'Counts the rows', 'Removes duplicate rows from the result', 'Joins tables', 'C', 'DISTINCT eliminates duplicate rows so each combination appears once.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the DISTINCT keyword do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does WHERE run before GROUP BY in logical processing?', 'Grouping always comes first', 'They run simultaneously', 'WHERE filters groups', 'Rows are filtered before being grouped and aggregated', 'D', 'Logically, WHERE removes rows first, then GROUP BY forms groups from the remaining rows.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does WHERE run before GROUP BY in logical processing?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the aggregate function COUNT(*) return?', 'The number of rows in each group or result', 'The sum of a column', 'The maximum value', 'Distinct values only', 'A', 'COUNT(*) counts rows, including those with nulls, in the current grouping or result set.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the aggregate function COUNT(*) return?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the UPDATE statement require to limit which rows change?', 'An ORDER BY', 'A WHERE clause', 'A GROUP BY', 'A JOIN', 'B', 'Without a WHERE clause UPDATE changes every row; WHERE restricts it to matching rows.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the UPDATE statement require to limit which rows change?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can SELECT * be discouraged in production queries?', 'It is slower to type', 'It sorts automatically', 'It returns unneeded columns and is fragile to schema changes', 'It deletes columns', 'C', 'Selecting all columns transfers unnecessary data and breaks when the schema changes; naming columns is safer.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can SELECT * be discouraged in production queries?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the LIKE operator do?', 'Compares numbers only', 'Joins tables', 'Sorts text', 'Matches text against a pattern with wildcards', 'D', 'LIKE matches string patterns, using wildcards such as % for any sequence of characters.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the LIKE operator do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the IN operator test?', 'Whether a value is in a given set or subquery result', 'Whether a table exists', 'Whether rows are sorted', 'Whether a column is null', 'A', 'IN checks membership of a value against a list or the results of a subquery.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the IN operator test?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How do you test for a missing value in SQL?', 'Using = NULL', 'Using IS NULL', 'Using == NULL', 'Using LIKE NULL', 'B', 'Because null comparisons are unknown, IS NULL is the correct way to test for missing values.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How do you test for a missing value in SQL?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the DELETE statement without a WHERE clause do?', 'Removes one row', 'Drops the table', 'Removes all rows from the table', 'Updates rows', 'C', 'DELETE with no WHERE deletes every row while leaving the table structure intact.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the DELETE statement without a WHERE clause do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an aggregate like AVG ignore by default?', 'The first row', 'Grouped rows', 'Indexed columns', 'Null values in the column', 'D', 'Standard aggregate functions skip nulls, computing over non-null values only.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an aggregate like AVG ignore by default?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the LIMIT (or FETCH FIRST) clause do?', 'Caps the number of returned rows', 'Filters by condition', 'Sorts rows', 'Groups rows', 'A', 'LIMIT restricts how many rows the query returns, often with ORDER BY for determinism.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the LIMIT (or FETCH FIRST) clause do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why pair LIMIT with ORDER BY for top-N queries?', 'LIMIT sorts automatically', 'Without ordering, which rows are returned is unpredictable', 'ORDER BY caps rows', 'They conflict otherwise', 'B', 'LIMIT alone returns an arbitrary subset; ORDER BY makes the chosen top-N deterministic.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why pair LIMIT with ORDER BY for top-N queries?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the BETWEEN operator test?', 'Whether two tables match', 'Whether a row is null', 'Whether a value falls within an inclusive range', 'Whether text matches a pattern', 'C', 'BETWEEN a AND b is true when the value is within the inclusive range from a to b.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the BETWEEN operator test?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the effect of aliasing a column with AS?', 'It filters the column', 'It deletes the column', 'It indexes the column', 'It renames the column in the result', 'D', 'AS assigns a label to a column or expression in the output without changing stored data.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the effect of aliasing a column with AS?');

  -- ---- Database Management Systems / Joins and Subqueries (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Database Management Systems'
    and t.topic_name = 'Joins and Subqueries';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Database Management Systems', 'Joins and Subqueries';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an INNER JOIN return?', 'Rows with matching values in both tables', 'All rows from the left table only', 'All rows from both tables', 'Rows from neither table', 'A', 'An inner join returns only the row combinations where the join condition matches in both tables.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an INNER JOIN return?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What distinguishes a LEFT OUTER JOIN from an inner join?', 'It drops all unmatched rows', 'It keeps unmatched left rows with nulls for the right', 'It keeps only right rows', 'It sorts the result', 'B', 'A left join preserves every left-table row, filling right-side columns with null when there is no match.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What distinguishes a LEFT OUTER JOIN from an inner join?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a self-join?', 'A join of three tables', 'A join without a condition', 'A table joined to itself', 'A join on primary keys only', 'C', 'A self-join relates rows within the same table, typically using table aliases.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a self-join?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a cross join produce?', 'Only matching rows', 'A single row', 'The left table only', 'The Cartesian product of the two tables', 'D', 'A cross join pairs every row of one table with every row of the other, producing the Cartesian product.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a cross join produce?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a correlated subquery?', 'A subquery that references the outer query''s row', 'A subquery run once independently', 'A join without conditions', 'A sorted subquery', 'A', 'A correlated subquery depends on each outer row and is conceptually evaluated per outer row.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a correlated subquery?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can a non-correlated subquery often be executed just once?', 'It references outer columns', 'It does not depend on the outer query''s rows', 'It must run per row', 'It sorts the outer query', 'B', 'An independent subquery produces a fixed result that the outer query can reuse.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can a non-correlated subquery often be executed just once?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a join condition typically compare?', 'Two unrelated constants', 'Row counts', 'A foreign key to a referenced key', 'Column names only', 'C', 'Joins usually match a foreign key in one table to the referenced key in another.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a join condition typically compare?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens if you omit the join condition in an inner join written with a comma?', 'You get an error always', 'You get an empty result', 'Rows are sorted', 'You get a Cartesian product', 'D', 'Without a condition the join degenerates into a Cartesian product of all row combinations.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens if you omit the join condition in an inner join written with a comma?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a RIGHT OUTER JOIN preserve?', 'All rows from the right table', 'All rows from the left table', 'Only matching rows', 'No rows', 'A', 'A right join keeps every right-table row, using nulls for unmatched left-side columns.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a RIGHT OUTER JOIN preserve?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a subquery in the FROM clause often called?', 'A correlated query', 'A derived table', 'A view trigger', 'An index scan', 'B', 'A subquery used as a table source in FROM is a derived table (or inline view).', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a subquery in the FROM clause often called?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why might EXISTS be used instead of IN with a subquery?', 'It sorts the result', 'It joins tables', 'It can stop at the first match and handle nulls differently', 'It is always slower', 'C', 'EXISTS tests for the presence of any matching row and avoids some null pitfalls of IN.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why might EXISTS be used instead of IN with a subquery?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a FULL OUTER JOIN return?', 'Only matching rows', 'Only left rows', 'Only right rows', 'All rows from both tables, matched where possible', 'D', 'A full outer join combines left and right joins, keeping unmatched rows from both sides with nulls.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a FULL OUTER JOIN return?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does joining on a non-unique column risk?', 'Producing duplicate or multiplied result rows', 'An automatic sort', 'Deleting rows', 'A single row only', 'A', 'If the join column has duplicates, each match can multiply rows in the result.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does joining on a non-unique column risk?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the purpose of a table alias in a join?', 'To delete a table', 'To reference tables briefly and disambiguate columns', 'To sort rows', 'To create an index', 'B', 'Aliases shorten references and resolve ambiguity when columns share names across tables.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the purpose of a table alias in a join?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a subquery returning a single scalar value allow?', 'Joining two tables', 'Grouping rows', 'Use in a comparison like column = (subquery)', 'Creating an index', 'C', 'A scalar subquery yields one value usable directly in comparisons or expressions.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a subquery returning a single scalar value allow?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can inner joins be reordered by the optimizer?', 'Order never matters in SQL', 'They always run left to right', 'They cannot be reordered', 'Inner join is commutative and associative', 'D', 'Because inner joins are commutative and associative, the optimizer may choose any efficient order.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can inner joins be reordered by the optimizer?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does joining three tables require?', 'Join conditions linking each pair appropriately', 'A single condition for all', 'No conditions', 'Only primary keys', 'A', 'Multi-table joins need conditions connecting the tables so rows combine meaningfully.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does joining three tables require?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a semi-join conceptually?', 'Returning the Cartesian product', 'Returning left rows that have at least one match', 'Returning unmatched rows', 'Returning right rows only', 'B', 'A semi-join keeps left rows that have a matching right row, without duplicating for multiple matches.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a semi-join conceptually?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can a correlated subquery be slower than an equivalent join?', 'Joins are always slower', 'It cannot use indexes', 'It may re-evaluate for each outer row', 'It sorts twice', 'C', 'Evaluating a correlated subquery per outer row can be costlier than a set-based join the optimizer handles well.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can a correlated subquery be slower than an equivalent join?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the USING clause in a join specify?', 'A sort order', 'A filter condition only', 'An index', 'A shared column name to join on', 'D', 'USING names a common column present in both tables to serve as the join key.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the USING clause in a join specify?');

  -- ---- Database Management Systems / Entity-Relationship Modeling (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Database Management Systems'
    and t.topic_name = 'Entity-Relationship Modeling';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Database Management Systems', 'Entity-Relationship Modeling';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an entity represent in an ER model?', 'A real-world object or concept with data', 'A single column value', 'A SQL query', 'An index', 'A', 'An entity is a distinguishable thing, like Student or Course, about which data is stored.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an entity represent in an ER model?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an attribute describe in an ER diagram?', 'A join between tables', 'A property of an entity', 'A stored procedure', 'A transaction', 'B', 'An attribute captures a property of an entity, such as a student''s name.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an attribute describe in an ER diagram?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a relationship connect in an ER model?', 'Two attributes only', 'A table and an index', 'Two or more entities', 'A query and a view', 'C', 'A relationship associates entities, such as Student enrolls in Course.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a relationship connect in an ER model?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a one-to-many relationship mean?', 'Each relates to exactly one', 'Many relate to many', 'None relate', 'One entity instance relates to many of another', 'D', 'In one-to-many, a single instance on one side links to multiple instances on the other.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a one-to-many relationship mean?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How is a many-to-many relationship typically implemented relationally?', 'With a junction table holding both foreign keys', 'With a single foreign key', 'By merging the tables', 'With an index only', 'A', 'A many-to-many relationship is resolved by a bridge table that references both entities'' keys.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How is a many-to-many relationship typically implemented relationally?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a weak entity?', 'An entity with many attributes', 'An entity that depends on another for identification', 'A table with no rows', 'A derived attribute', 'B', 'A weak entity cannot be uniquely identified by its own attributes and relies on an owner entity.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a weak entity?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does cardinality specify in a relationship?', 'The number of attributes', 'The primary key length', 'How many instances of one entity relate to another', 'The index type', 'C', 'Cardinality constrains how many instances participate, such as one-to-one or one-to-many.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does cardinality specify in a relationship?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a composite attribute?', 'An attribute shared by entities', 'A foreign key', 'A derived value only', 'An attribute composed of sub-attributes', 'D', 'A composite attribute, like Address, breaks down into components such as street and city.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a composite attribute?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a derived attribute?', 'A value computed from other attributes', 'A stored primary key', 'A junction table', 'A null column', 'A', 'A derived attribute, such as age from birthdate, is calculated rather than stored directly.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a derived attribute?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why map an entity to a table in the relational model?', 'Entities cannot be stored', 'Each entity''s instances become rows in its table', 'Relationships become columns only', 'Tables replace attributes', 'B', 'The ER-to-relational mapping turns each entity set into a table and its instances into rows.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why map an entity to a table in the relational model?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does participation (total vs partial) describe?', 'The number of attributes', 'The sort order', 'Whether every instance must take part in a relationship', 'The index coverage', 'C', 'Total participation means every entity instance must participate; partial means some may not.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does participation (total vs partial) describe?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a multivalued attribute?', 'A single-value key', 'A foreign key', 'A derived value', 'An attribute that can hold multiple values', 'D', 'A multivalued attribute, like phone numbers, can take several values for one entity instance.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a multivalued attribute?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How is a multivalued attribute usually represented relationally?', 'With a separate table linked by a foreign key', 'As one text column', 'As a primary key', 'As an index', 'A', 'Because tables store atomic values, multivalued attributes move to a separate related table.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How is a multivalued attribute usually represented relationally?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is an identifying relationship?', 'A many-to-many link', 'One that provides a weak entity part of its key', 'A derived attribute', 'A sort rule', 'B', 'An identifying relationship links a weak entity to its owner, contributing to the weak entity''s identifier.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is an identifying relationship?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a key attribute uniquely do?', 'Store derived data', 'Link two relationships', 'Identify each instance of an entity', 'Hold multiple values', 'C', 'A key attribute uniquely identifies instances, becoming the primary key in the mapped table.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a key attribute uniquely do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why model relationships explicitly before creating tables?', 'Tables cannot be created otherwise', 'It replaces normalization', 'It removes keys', 'It clarifies how data connects and avoids design errors', 'D', 'An ER model surfaces how entities relate, guiding a correct and consistent table design.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why model relationships explicitly before creating tables?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a one-to-one relationship allow in table design?', 'Merging into one table or linking by a shared key', 'Only a junction table', 'Many foreign keys', 'No foreign key', 'A', 'One-to-one relationships can be combined into a single table or linked with a foreign/shared key.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a one-to-one relationship allow in table design?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a recursive relationship?', 'A relationship among three entities', 'A relationship of an entity type to itself', 'A derived attribute', 'A junction table', 'B', 'A recursive relationship connects instances of the same entity, like Employee manages Employee.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a recursive relationship?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an ER diagram help communicate?', 'The exact SQL syntax', 'The server hardware', 'The structure of data and its relationships to stakeholders', 'Index internals', 'C', 'ER diagrams give a visual, shared understanding of entities, attributes, and relationships.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an ER diagram help communicate?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What becomes of a relationship''s own attributes when mapped relationally?', 'They are discarded', 'They become indexes', 'They become entities', 'They are placed in the appropriate table, often the junction table', 'D', 'Attributes describing a relationship are stored where the relationship is represented, commonly the junction table.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What becomes of a relationship''s own attributes when mapped relationally?');

  -- ---- Database Management Systems / Normalization (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Database Management Systems'
    and t.topic_name = 'Normalization';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Database Management Systems', 'Normalization';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the main goal of normalization?', 'Reduce redundancy and avoid update anomalies', 'Increase duplicate data', 'Remove all tables', 'Speed up every query', 'A', 'Normalization organizes data to minimize redundancy and the anomalies it causes.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the main goal of normalization?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does first normal form require?', 'No foreign keys', 'Atomic values with no repeating groups', 'A single table', 'Full transitive dependencies', 'B', '1NF requires each attribute to hold a single atomic value, eliminating repeating groups.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does first normal form require?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a functional dependency?', 'Two unrelated columns', 'A foreign key link', 'One attribute set determines another', 'A sort order', 'C', 'A functional dependency X -> Y means each X value determines a single Y value.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a functional dependency?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does second normal form eliminate?', 'All foreign keys', 'Transitive dependencies', 'Atomic values', 'Partial dependency on part of a composite key', 'D', '2NF removes dependencies on only part of a composite primary key, requiring full-key dependence.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does second normal form eliminate?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does third normal form eliminate?', 'Transitive dependencies on non-key attributes', 'Partial dependencies', 'Atomic values', 'All relationships', 'A', '3NF removes transitive dependencies so non-key attributes depend only on the key.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does third normal form eliminate?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is an update anomaly?', 'A missing index', 'Needing to change the same fact in many places', 'A sorted table', 'A foreign key', 'B', 'Redundant data causes update anomalies: a single fact stored repeatedly must be changed everywhere.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is an update anomaly?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is an insertion anomaly?', 'A duplicate index', 'A fast insert', 'Inability to add data without unrelated data', 'A sorted insert', 'C', 'An insertion anomaly arises when you cannot record one fact without also supplying unrelated information.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is an insertion anomaly?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a deletion anomaly?', 'A faster delete', 'A missing key', 'A sorted delete', 'Losing unrelated facts when a row is deleted', 'D', 'A deletion anomaly occurs when removing a row unintentionally erases other, unrelated information.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a deletion anomaly?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does Boyce-Codd normal form strengthen?', 'Every determinant must be a candidate key', 'That tables have no keys', 'First normal form only', 'Atomicity rules', 'A', 'BCNF requires that for every functional dependency, the left side is a superkey, tightening 3NF.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does Boyce-Codd normal form strengthen?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can over-normalization hurt read performance?', 'It stores more duplicates', 'It requires more joins to reassemble data', 'It removes keys', 'It sorts tables', 'B', 'Splitting data across many tables can force expensive joins when reading combined information.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can over-normalization hurt read performance?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is denormalization?', 'Removing all data', 'Enforcing 3NF strictly', 'Intentionally adding redundancy for performance', 'Dropping foreign keys', 'C', 'Denormalization reintroduces controlled redundancy to speed reads at the cost of some integrity management.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is denormalization?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a transitive dependency look like?', 'A determines A', 'No determination', 'A and B are keys', 'A determines B and B determines C', 'D', 'A transitive dependency chains A -> B -> C, so C depends on A indirectly through B.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a transitive dependency look like?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is storing a customer''s city derived from a zip code a normalization concern?', 'It creates a transitive dependency to resolve', 'It is always required', 'Zip codes have no city', 'Cities are keys', 'A', 'City depending on zip (not the key directly) is a transitive dependency addressed by 3NF.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is storing a customer''s city derived from a zip code a normalization concern?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does normalization trade away for cleaner structure?', 'All data integrity', 'Some read performance due to more joins', 'The ability to insert', 'Primary keys', 'B', 'Normalized designs reduce redundancy but can require joins that cost read performance.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does normalization trade away for cleaner structure?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a partial dependency?', 'A dependency on the whole key', 'A transitive chain', 'A non-key attribute depends on part of a composite key', 'A foreign key', 'C', 'A partial dependency means a non-key attribute depends on only a portion of a composite key, violating 2NF.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a partial dependency?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which normal form must be satisfied before considering 2NF?', 'Third normal form', 'BCNF', 'None', 'First normal form', 'D', 'Normalization proceeds in order, so 1NF must hold before a table can be in 2NF.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which normal form must be satisfied before considering 2NF?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does normalization help prevent in stored facts?', 'Inconsistent duplicate copies of the same data', 'All queries', 'Index creation', 'Key constraints', 'A', 'By removing redundancy, normalization avoids conflicting copies of the same fact.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does normalization help prevent in stored facts?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is atomicity of values important for 1NF?', 'It speeds all joins', 'Non-atomic values complicate querying and integrity', 'It removes keys', 'It adds duplicates', 'B', 'Atomic single-valued fields make querying and constraint enforcement straightforward, as 1NF requires.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is atomicity of values important for 1NF?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the typical outcome of decomposing a table during normalization?', 'A single wider table', 'No tables', 'Two or more tables linked by keys', 'An index only', 'C', 'Normalization decomposes a table into related tables connected by primary and foreign keys.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the typical outcome of decomposing a table during normalization?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'When might a team deliberately choose a less-normalized schema?', 'To maximize anomalies', 'To remove all keys', 'To slow down reads', 'For read-heavy workloads needing fewer joins', 'D', 'Read-heavy systems sometimes denormalize to reduce joins and speed queries, accepting managed redundancy.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'When might a team deliberately choose a less-normalized schema?');

  -- ---- Database Management Systems / Transactions and ACID (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Database Management Systems'
    and t.topic_name = 'Transactions and ACID';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Database Management Systems', 'Transactions and ACID';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the A in ACID stand for?', 'Atomicity', 'Availability', 'Alignment', 'Aggregation', 'A', 'Atomicity means a transaction''s operations all succeed or all fail as a unit.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the A in ACID stand for?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does atomicity guarantee for a transaction?', 'Operations run in parallel', 'All operations commit together or none do', 'Only reads succeed', 'Rows are sorted', 'B', 'Atomicity ensures a transaction is indivisible: it either fully completes or has no effect.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does atomicity guarantee for a transaction?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does consistency ensure in ACID?', 'Fast queries', 'No indexes', 'The database moves between valid states', 'Parallel writes', 'C', 'Consistency means a transaction brings the database from one valid state to another, respecting constraints.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does consistency ensure in ACID?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does isolation address?', 'How data is stored on disk', 'The number of columns', 'Index selection', 'How concurrent transactions affect each other', 'D', 'Isolation controls the visibility of concurrent transactions'' intermediate changes to one another.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does isolation address?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does durability guarantee?', 'Committed changes survive crashes', 'Changes are temporary', 'Reads are fast', 'Rows are sorted', 'A', 'Durability ensures that once committed, a transaction''s effects persist even after a failure.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does durability guarantee?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a COMMIT do?', 'Undoes the transaction', 'Makes the transaction''s changes permanent', 'Starts a new transaction', 'Locks the table forever', 'B', 'COMMIT finalizes a transaction, making its changes durable and visible per the isolation level.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a COMMIT do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does ROLLBACK do?', 'Commits changes', 'Creates an index', 'Undoes the current transaction''s changes', 'Sorts rows', 'C', 'ROLLBACK discards the uncommitted work of a transaction, returning to the prior state.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does ROLLBACK do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a dirty read?', 'Reading committed data', 'Reading an index', 'Reading sorted rows', 'Reading uncommitted changes from another transaction', 'D', 'A dirty read sees another transaction''s changes that may later be rolled back.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a dirty read?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What anomaly does a non-repeatable read describe?', 'Re-reading a row yields different committed values', 'Reading uncommitted data', 'A missing index', 'A sorted result', 'A', 'A non-repeatable read occurs when a row read twice differs because another transaction committed a change.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What anomaly does a non-repeatable read describe?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a phantom read?', 'A single row changes', 'New rows appear in a repeated range query', 'An index is dropped', 'A deadlock occurs', 'B', 'A phantom read happens when a repeated range query returns additional rows inserted by another transaction.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a phantom read?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which isolation level prevents dirty reads but may allow non-repeatable reads?', 'Read Uncommitted', 'Serializable', 'Read Committed', 'None', 'C', 'Read Committed blocks reading uncommitted data but can still see different values on re-read.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which isolation level prevents dirty reads but may allow non-repeatable reads?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the Serializable isolation level provide?', 'The fastest concurrency', 'No isolation', 'Only dirty reads', 'Behavior as if transactions ran one at a time', 'D', 'Serializable is the strictest level, making concurrent execution equivalent to some serial order.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the Serializable isolation level provide?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is higher isolation often slower?', 'It adds locking or validation that reduces concurrency', 'It removes durability', 'It skips commits', 'It avoids reads', 'A', 'Stronger isolation uses more locking or checks, limiting how much work can proceed concurrently.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is higher isolation often slower?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a deadlock between transactions?', 'A single long query', 'Each waits for a lock the other holds', 'A committed transaction', 'A missing index', 'B', 'A deadlock occurs when transactions wait on each other''s locks, so none can proceed.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a deadlock between transactions?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How do databases commonly resolve a deadlock?', 'Wait indefinitely', 'Commit both', 'Abort one transaction to break the cycle', 'Drop a table', 'C', 'The system detects the cycle and rolls back a victim transaction so the others can continue.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How do databases commonly resolve a deadlock?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a write-ahead log support?', 'Faster indexing', 'Sorting rows', 'Removing locks', 'Durability and recovery after a crash', 'D', 'A write-ahead log records changes before applying them, enabling recovery and durability.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a write-ahead log support?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a savepoint within a transaction?', 'A marker to partially roll back to', 'A full commit', 'A new transaction', 'An index', 'A', 'A savepoint lets a transaction roll back to a point without discarding all its work.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a savepoint within a transaction?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why group multiple operations into one transaction?', 'To slow them down', 'To keep related changes atomic and consistent', 'To avoid commits', 'To skip isolation', 'B', 'A transaction ensures related changes apply together, preserving integrity if any step fails.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why group multiple operations into one transaction?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens to a transaction''s changes if the system crashes before COMMIT?', 'They become permanent', 'They are committed automatically', 'They are not durable and are rolled back on recovery', 'They are indexed', 'C', 'Uncommitted work is not durable, so recovery discards it to maintain consistency.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens to a transaction''s changes if the system crashes before COMMIT?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does optimistic concurrency control assume?', 'Every operation conflicts', 'Locks are always held', 'No validation is needed', 'Conflicts are rare and checked at commit time', 'D', 'Optimistic control proceeds without locking and validates for conflicts when committing.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does optimistic concurrency control assume?');

  -- ---- Database Management Systems / Indexing (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Database Management Systems'
    and t.topic_name = 'Indexing';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Database Management Systems', 'Indexing';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the main purpose of a database index?', 'Speed up data retrieval for certain queries', 'Store duplicate data', 'Enforce atomicity', 'Sort the disk', 'A', 'An index provides a fast lookup structure that accelerates queries on indexed columns.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the main purpose of a database index?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What data structure commonly backs a general-purpose index?', 'A hash of the whole table', 'A B-tree', 'A linked list of rows', 'A heap of columns', 'B', 'B-tree indexes keep keys sorted in a balanced tree, supporting range and equality lookups.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What data structure commonly backs a general-purpose index?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the trade-off of adding many indexes?', 'Faster writes always', 'Less storage used', 'Faster reads but slower writes and more storage', 'No effect on writes', 'C', 'Each index speeds some reads but must be maintained on writes and consumes storage.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the trade-off of adding many indexes?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can an index on a low-selectivity column be ineffective?', 'It is too selective', 'It cannot be created', 'It sorts the table', 'It matches too many rows to help much', 'D', 'If most rows share a value, the index narrows little and a scan may be just as efficient.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can an index on a low-selectivity column be ineffective?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a composite index?', 'An index on multiple columns in order', 'An index on one column', 'A duplicate of the table', 'A hash of a row', 'A', 'A composite index covers several columns, useful when queries filter or sort by that column order.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a composite index?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does column order matter in a composite index?', 'Order is irrelevant', 'Leftmost columns must be used for the index to help', 'Only the last column matters', 'It sorts rows randomly', 'B', 'A composite index is most useful when queries filter on a leftmost prefix of its columns.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does column order matter in a composite index?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a covering index?', 'An index on no columns', 'A duplicate table', 'An index containing all columns a query needs', 'A hash index only', 'C', 'A covering index satisfies a query entirely from the index, avoiding row lookups.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a covering index?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a unique index enforce?', 'Faster writes', 'Sorted output always', 'Null values only', 'No duplicate values in the indexed column(s)', 'D', 'A unique index guarantees uniqueness of the indexed values in addition to speeding lookups.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a unique index enforce?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can a function applied to an indexed column disable the index?', 'The stored index keys no longer match the expression', 'Functions always use indexes', 'Indexes ignore functions', 'It sorts the index', 'A', 'Wrapping a column in a function means the plain index keys cannot be matched directly, often causing a scan.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can a function applied to an indexed column disable the index?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a clustered index?', 'An index with no keys', 'One that determines the physical row order', 'A duplicate of a hash', 'A secondary index only', 'B', 'A clustered index stores rows in index order, so the table''s physical order follows the key.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a clustered index?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How many clustered indexes can a table have?', 'As many as columns', 'Zero only', 'One', 'Unlimited', 'C', 'Because it defines physical order, a table can have at most one clustered index.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How many clustered indexes can a table have?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a hash index support well?', 'Range queries', 'Sorted scans', 'Prefix matching', 'Fast equality lookups', 'D', 'Hash indexes excel at exact-match equality lookups but not range or ordered queries.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a hash index support well?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why might the optimizer ignore an index for a query returning most rows?', 'A full scan can be cheaper than many index lookups', 'Indexes cannot be ignored', 'Scans are always slower', 'The index is sorted', 'A', 'When a query returns a large fraction of rows, scanning sequentially often beats random index access.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why might the optimizer ignore an index for a query returning most rows?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is index selectivity?', 'The index file size', 'How well the index distinguishes rows', 'The number of tables', 'The sort order', 'B', 'Selectivity measures how many distinct values an index has relative to rows; higher selectivity is more useful.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is index selectivity?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What maintenance cost do indexes add on INSERT?', 'No cost at all', 'The table is dropped', 'Each index must be updated for the new row', 'Rows are sorted once', 'C', 'Inserting a row requires updating every index on the table, adding write overhead.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What maintenance cost do indexes add on INSERT?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an index on a foreign key column often improve?', 'Row deletion speed only', 'Storage usage', 'Transaction isolation', 'Join and lookup performance to the parent table', 'D', 'Indexing foreign keys speeds joins and referential checks against the referenced table.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an index on a foreign key column often improve?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a partial index?', 'An index built over a subset of rows meeting a condition', 'An index on half the columns', 'A duplicate index', 'An unindexed table', 'A', 'A partial index covers only rows satisfying a predicate, saving space when queries target that subset.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a partial index?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can too many indexes slow bulk data loads?', 'They speed loads', 'Every inserted row updates all indexes', 'They remove constraints', 'They sort nothing', 'B', 'Bulk inserts must maintain each index per row, so numerous indexes slow loading significantly.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can too many indexes slow bulk data loads?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an index range scan do?', 'Reads one random row', 'Scans the whole heap', 'Reads a contiguous range of index entries', 'Rebuilds the index', 'C', 'A range scan walks a sorted span of the index to find rows within bounds, as in BETWEEN queries.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an index range scan do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What should guide which columns to index?', 'Random columns', 'Only primary keys', 'Columns never queried', 'The columns frequently used in filters and joins', 'D', 'Indexes help most on columns commonly used in WHERE conditions, joins, and ordering.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What should guide which columns to index?');

  -- ---- Operating Systems / Processes and Threads (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Operating Systems'
    and t.topic_name = 'Processes and Threads';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Operating Systems', 'Processes and Threads';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a process?', 'A program in execution with its own address space', 'A line of source code', 'A disk file only', 'A CPU register', 'A', 'A process is an executing program with its own memory, resources, and execution context.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a process?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does a thread differ from a process?', 'Threads have separate address spaces', 'Threads of a process share its address space', 'A thread cannot run code', 'A process has one register', 'B', 'Threads within a process share memory and resources, while separate processes do not.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does a thread differ from a process?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the process control block store?', 'Only the program name', 'The entire disk', 'Process state, registers, and scheduling info', 'User passwords', 'C', 'The PCB holds a process''s state, saved registers, memory info, and scheduling data.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the process control block store?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is context switching between threads often cheaper than between processes?', 'Threads have more state', 'Processes share memory', 'There is no difference', 'Threads share the address space, so less state changes', 'D', 'Switching threads avoids changing the address space, reducing the saved and restored state.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is context switching between threads often cheaper than between processes?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What are the typical states in a process lifecycle?', 'Ready, running, and waiting (blocked)', 'Open and closed only', 'Sorted and unsorted', 'Fast and slow', 'A', 'A process moves among ready, running, and waiting states as it is scheduled and performs I/O.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What are the typical states in a process lifecycle?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the fork system call do on Unix-like systems?', 'Terminates a process', 'Creates a child process copying the parent', 'Switches threads', 'Allocates a file', 'B', 'fork spawns a child process that is initially a copy of the parent''s address space.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the fork system call do on Unix-like systems?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can multithreading improve throughput on multicore CPUs?', 'Threads disable cores', 'One core runs faster', 'Threads can run in parallel on different cores', 'Threads avoid the CPU', 'C', 'Multiple threads can execute simultaneously across cores, increasing parallel throughput.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can multithreading improve throughput on multicore CPUs?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a race condition?', 'A fast process', 'A sorted queue', 'A single-threaded bug only', 'An outcome depending on unpredictable thread timing', 'D', 'A race condition occurs when concurrent accesses to shared state produce timing-dependent results.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a race condition?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an inter-process communication mechanism provide?', 'A way for separate processes to exchange data', 'Shared registers automatically', 'Faster CPUs', 'A single thread', 'A', 'IPC mechanisms like pipes and message queues let isolated processes communicate.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an inter-process communication mechanism provide?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which term describes a terminated child whose exit status the parent has not yet collected?', 'Orphan', 'Zombie', 'Daemon', 'Spinlock', 'B', 'A zombie child has terminated but lingers in the process table until its parent reads its exit status.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which term describes a terminated child whose exit status the parent has not yet collected?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a thread of execution minimally contain?', 'A separate address space', 'A full copy of the process', 'Its own stack and program counter', 'A disk partition', 'C', 'Each thread has its own stack and program counter while sharing the process''s memory.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a thread of execution minimally contain?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why do shared variables between threads require synchronization?', 'They are never shared', 'Threads cannot write', 'The CPU prevents it', 'Concurrent updates can corrupt shared state', 'D', 'Unsynchronized concurrent access can interleave updates and corrupt shared data.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why do shared variables between threads require synchronization?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which term names a background service that typically starts at boot and runs without a terminal?', 'Daemon', 'Zombie', 'Foreground job', 'Context switch', 'A', 'A daemon runs in the background, often launched at boot, to provide ongoing services without a terminal.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which term names a background service that typically starts at boot and runs without a terminal?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the operating system scheduler decide?', 'How files are named', 'Which ready process or thread runs next', 'The disk layout', 'The network address', 'B', 'The scheduler selects which runnable process or thread the CPU executes next.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the operating system scheduler decide?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is user-level versus kernel-level threading?', 'Whether threads use the CPU', 'The thread''s stack size', 'Whether the kernel is aware of and schedules threads', 'The number of cores', 'C', 'Kernel-level threads are scheduled by the OS; user-level threads are managed in user space, invisible to the kernel.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is user-level versus kernel-level threading?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens to child processes when their parent exits in many systems?', 'They are duplicated', 'They gain more memory', 'They become threads', 'They may be reparented to a system process', 'D', 'Orphaned children are typically adopted by an init-like process to collect their status.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens to child processes when their parent exits in many systems?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is process isolation valuable?', 'One process''s fault is less likely to crash others', 'It shares all memory', 'It speeds the CPU', 'It removes scheduling', 'A', 'Separate address spaces contain faults, so a crashing process does not corrupt others.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is process isolation valuable?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a thread pool manage?', 'A list of files', 'A set of reusable worker threads', 'Disk sectors', 'Network routes', 'B', 'A thread pool reuses a fixed set of threads to handle many tasks, avoiding repeated thread creation.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a thread pool manage?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is concurrency as distinct from parallelism?', 'Running tasks on one bit', 'Only using one core', 'Managing multiple tasks that may overlap in progress', 'Sorting tasks', 'C', 'Concurrency structures overlapping tasks; parallelism actually runs them at the same time on multiple cores.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is concurrency as distinct from parallelism?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does terminating a process release?', 'Nothing at all', 'The entire disk', 'Other processes'' memory', 'Its allocated resources back to the system', 'D', 'When a process ends, the OS reclaims its memory, open files, and other resources.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does terminating a process release?');

  -- ---- Operating Systems / CPU Scheduling (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Operating Systems'
    and t.topic_name = 'CPU Scheduling';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Operating Systems', 'CPU Scheduling';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the goal of CPU scheduling?', 'Decide which ready process gets the CPU and when', 'Format the disk', 'Encrypt files', 'Assign IP addresses', 'A', 'CPU scheduling chooses among ready processes to use the processor efficiently and fairly.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the goal of CPU scheduling?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What characterizes preemptive scheduling?', 'A process runs to completion always', 'The scheduler can interrupt a running process', 'No process ever runs', 'Processes pick themselves', 'B', 'Preemptive scheduling can forcibly take the CPU from a running process to run another.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What characterizes preemptive scheduling?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the first-come, first-served policy do?', 'Runs the shortest job first', 'Uses time slices', 'Runs processes in arrival order', 'Runs by priority only', 'C', 'FCFS schedules processes in the order they arrive, without preemption.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the first-come, first-served policy do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can FCFS cause the convoy effect?', 'Short jobs block long jobs', 'It preempts constantly', 'It uses priorities', 'A long job delays many short jobs behind it', 'D', 'A lengthy process at the front forces shorter ones to wait, hurting average waiting time.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can FCFS cause the convoy effect?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does shortest-job-first optimize?', 'Average waiting time', 'Maximum response time', 'Disk usage', 'Memory size', 'A', 'SJF minimizes average waiting time by running the shortest available job next.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does shortest-job-first optimize?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What practical difficulty does SJF face?', 'Jobs have no length', 'Future burst lengths are not known in advance', 'It cannot preempt', 'It needs no queue', 'B', 'SJF requires knowing each job''s CPU burst length, which must be estimated in practice.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What practical difficulty does SJF face?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does round-robin scheduling use?', 'Priorities only', 'Arrival order only', 'Fixed time slices rotated among processes', 'Job lengths', 'C', 'Round-robin gives each process a time quantum in turn, promoting fairness and responsiveness.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does round-robin scheduling use?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does the time quantum affect round-robin behavior?', 'It has no effect', 'Larger is always better', 'Smaller removes context switches', 'Too small raises overhead; too large approaches FCFS', 'D', 'A tiny quantum causes frequent switching overhead, while a huge quantum behaves like FCFS.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does the time quantum affect round-robin behavior?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is starvation in priority scheduling?', 'Low-priority processes may never run', 'All processes run equally', 'The CPU idles', 'High-priority jobs wait', 'A', 'Under strict priority, continually arriving high-priority work can starve low-priority processes.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is starvation in priority scheduling?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What technique counters starvation?', 'Lowering all priorities', 'Aging, which raises waiting processes'' priority', 'Removing the scheduler', 'Disabling preemption', 'B', 'Aging gradually increases the priority of long-waiting processes so they eventually run.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What technique counters starvation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is turnaround time?', 'Time spent only running', 'Time waiting in queue only', 'Total time from submission to completion', 'Context-switch time', 'C', 'Turnaround time measures the whole interval from arrival to completion.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is turnaround time?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is response time in interactive systems?', 'Total execution time', 'Disk latency', 'Memory access time', 'Time from request to first response', 'D', 'Response time is how long until a process first produces output, important for interactivity.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is response time in interactive systems?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a multilevel queue scheduler do?', 'Separates processes into queues with their own policies', 'Uses one queue only', 'Ignores priorities', 'Runs jobs randomly', 'A', 'A multilevel queue partitions processes into queues, each possibly scheduled differently.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a multilevel queue scheduler do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What distinguishes a multilevel feedback queue?', 'Queues never change', 'Processes can move between queues based on behavior', 'It has one priority', 'It is non-preemptive', 'B', 'A feedback queue lets processes migrate between queues according to their observed CPU usage.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What distinguishes a multilevel feedback queue?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does context-switch overhead matter to scheduling?', 'Switches are free', 'It speeds all jobs', 'Frequent switches waste CPU time on bookkeeping', 'It replaces the queue', 'C', 'Each switch saves and restores state, so excessive switching reduces useful CPU work.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does context-switch overhead matter to scheduling?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does CPU utilization measure?', 'The disk speed', 'Memory capacity', 'Network bandwidth', 'The fraction of time the CPU is busy', 'D', 'CPU utilization is the proportion of time the processor is doing work rather than idling.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does CPU utilization measure?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'In preemptive SJF (shortest remaining time), what triggers a possible switch?', 'A new job with a shorter remaining time arrives', 'A disk read finishes', 'The quantum never ends', 'A file is opened', 'A', 'Shortest-remaining-time preempts the running job when a job with less remaining time arrives.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'In preemptive SJF (shortest remaining time), what triggers a possible switch?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a scheduling criterion that favors interactive users?', 'High turnaround time', 'Low response time', 'Maximum waiting time', 'Large quantum only', 'B', 'Interactive systems prioritize low response time so users see quick feedback.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a scheduling criterion that favors interactive users?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is fairness a scheduling concern?', 'Only one process matters', 'The CPU should idle', 'Every process should get reasonable CPU access', 'Queues are unnecessary', 'C', 'Fair scheduling prevents some processes from monopolizing the CPU while others wait indefinitely.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is fairness a scheduling concern?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does non-preemptive scheduling imply?', 'The CPU is taken anytime', 'Processes never run', 'Quanta are enforced', 'A running process keeps the CPU until it yields or finishes', 'D', 'Without preemption, a process holds the CPU until it blocks or completes.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does non-preemptive scheduling imply?');

  -- ---- Operating Systems / Process Synchronization (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Operating Systems'
    and t.topic_name = 'Process Synchronization';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Operating Systems', 'Process Synchronization';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a critical section?', 'Code that accesses shared resources and must not interleave', 'Any fast function', 'A disk sector', 'A scheduling queue', 'A', 'A critical section accesses shared data and must be executed by one thread at a time.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a critical section?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does mutual exclusion ensure?', 'All threads enter together', 'Only one thread is in the critical section at a time', 'No thread ever enters', 'Threads run in order', 'B', 'Mutual exclusion guarantees that at most one thread executes the critical section concurrently.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does mutual exclusion ensure?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a mutex?', 'A counter of resources', 'A scheduling policy', 'A lock allowing one holder at a time', 'A file descriptor', 'C', 'A mutex is a mutual-exclusion lock that only one thread can hold at once.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a mutex?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a semaphore generalize beyond a mutex?', 'It allows zero holders', 'It schedules the CPU', 'It formats disks', 'It can allow a counted number of concurrent holders', 'D', 'A counting semaphore permits up to N holders, generalizing the binary lock behavior.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a semaphore generalize beyond a mutex?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What are the two classic semaphore operations?', 'wait (P) and signal (V)', 'lock and format', 'read and write', 'open and close', 'A', 'wait decrements and may block; signal increments and may wake a waiter.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What are the two classic semaphore operations?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What problem does busy-waiting (spinning) have?', 'It blocks the thread efficiently', 'It wastes CPU cycles while waiting', 'It never acquires the lock', 'It frees the CPU', 'B', 'A spinlock repeatedly checks a condition, consuming CPU while it waits.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What problem does busy-waiting (spinning) have?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'When can a spinlock be appropriate?', 'When waits are very long', 'When the CPU is idle only', 'When the wait is expected to be very short', 'Never', 'C', 'Spinning avoids context-switch overhead when the lock is held only briefly.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'When can a spinlock be appropriate?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a condition variable used for?', 'Counting resources', 'Scheduling threads', 'Formatting memory', 'Waiting until a condition becomes true, releasing a lock', 'D', 'A condition variable lets a thread wait for a predicate, atomically releasing and reacquiring a lock.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a condition variable used for?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the producer-consumer problem about?', 'Coordinating a shared bounded buffer safely', 'Scheduling the CPU', 'Formatting disks', 'Routing packets', 'A', 'It coordinates producers adding to and consumers removing from a shared buffer without conflict.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the producer-consumer problem about?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why must lock acquisition and release be balanced?', 'It speeds the CPU', 'Failing to release a lock can block other threads forever', 'Locks need no release', 'Release comes first', 'B', 'A lock held and never released prevents other threads from entering the critical section.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why must lock acquisition and release be balanced?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a deadlock in synchronization?', 'A single fast thread', 'An idle CPU', 'Threads each wait for locks the others hold', 'A sorted buffer', 'C', 'A deadlock arises when threads hold locks and wait on each other''s locks indefinitely.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a deadlock in synchronization?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a reader-writer lock allow?', 'Only one reader ever', 'Writers and readers together always', 'No access', 'Multiple readers or one writer at a time', 'D', 'A reader-writer lock permits concurrent reads but exclusive writes.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a reader-writer lock allow?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is an atomic operation?', 'One that completes without observable interruption', 'A slow operation', 'A disk write', 'A scheduling event', 'A', 'An atomic operation appears indivisible, so no other thread sees a partial result.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is an atomic operation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is a test-and-set instruction useful for locks?', 'It schedules threads', 'It atomically reads and sets a flag to coordinate access', 'It formats memory', 'It counts resources', 'B', 'Test-and-set atomically checks and updates a lock flag, enabling simple mutual exclusion.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is a test-and-set instruction useful for locks?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does signaling a condition variable do?', 'Blocks the signaler', 'Formats the lock', 'Wakes one or more threads waiting on it', 'Removes the thread', 'C', 'Signaling notifies waiting threads that the awaited condition may now hold.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does signaling a condition variable do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is priority inversion?', 'High priority always wins', 'Threads have no priority', 'Locks have priority', 'A low-priority thread holding a lock blocks a high-priority one', 'D', 'Priority inversion occurs when a high-priority thread waits on a lock held by a lower-priority thread.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is priority inversion?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a barrier synchronization do?', 'Makes threads wait until all reach a point', 'Runs one thread only', 'Removes locks', 'Schedules the CPU', 'A', 'A barrier blocks threads until every participating thread arrives, then releases them together.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a barrier synchronization do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why avoid holding a lock while performing slow I/O?', 'I/O needs the lock', 'It blocks other threads for the I/O duration', 'It speeds I/O', 'Locks require I/O', 'B', 'Keeping a lock during slow I/O serializes threads unnecessarily, hurting concurrency.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why avoid holding a lock while performing slow I/O?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the purpose of a monitor construct?', 'Scheduling the CPU', 'Formatting disks', 'Encapsulating shared data with synchronized methods', 'Counting cores', 'C', 'A monitor bundles shared data with methods that enforce mutual exclusion automatically.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the purpose of a monitor construct?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What property must a correct mutual-exclusion solution avoid?', 'Letting one thread enter', 'Releasing locks', 'Using condition variables', 'Allowing two threads in the critical section at once', 'D', 'A correct solution must never permit two threads in the critical section simultaneously.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What property must a correct mutual-exclusion solution avoid?');

  -- ---- Operating Systems / Deadlocks (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Operating Systems'
    and t.topic_name = 'Deadlocks';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Operating Systems', 'Deadlocks';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a deadlock?', 'A set of processes each waiting for resources held by others', 'A single idle process', 'A fast context switch', 'A full disk', 'A', 'In a deadlock, processes form a cycle of waiting, so none can proceed.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a deadlock?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which is one of the four necessary conditions for deadlock?', 'Infinite memory', 'Mutual exclusion of resources', 'A single process', 'No scheduling', 'B', 'Deadlock requires mutual exclusion, hold-and-wait, no preemption, and circular wait together.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which is one of the four necessary conditions for deadlock?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the hold-and-wait condition mean?', 'A process holds nothing', 'Resources are preemptible', 'A process holds resources while waiting for more', 'No process waits', 'C', 'Hold-and-wait occurs when a process keeps acquired resources while requesting additional ones.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the hold-and-wait condition mean?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the circular wait condition describe?', 'A single waiting process', 'No waiting at all', 'A sorted queue', 'A cycle of processes each waiting on the next', 'D', 'Circular wait is a closed chain where each process waits for a resource the next one holds.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the circular wait condition describe?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does deadlock prevention attack the problem?', 'By ensuring one necessary condition cannot hold', 'By ignoring resources', 'By adding more processes', 'By speeding the CPU', 'A', 'Prevention designs the system so at least one of the four necessary conditions never occurs.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does deadlock prevention attack the problem?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does requesting all resources at once prevent?', 'Mutual exclusion', 'Hold-and-wait', 'Preemption', 'Scheduling', 'B', 'Acquiring everything up front removes hold-and-wait, since a process waits before holding any.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does requesting all resources at once prevent?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How can imposing a global resource ordering help?', 'It removes mutual exclusion', 'It adds preemption', 'It prevents circular wait', 'It speeds I/O', 'C', 'If resources are always requested in a fixed order, no cycle of waits can form.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How can imposing a global resource ordering help?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the banker''s algorithm used for?', 'Deadlock detection after the fact', 'Scheduling the CPU', 'Formatting disks', 'Deadlock avoidance by granting only safe requests', 'D', 'The banker''s algorithm grants a request only if the resulting state is safe, avoiding deadlock.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the banker''s algorithm used for?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a safe state in deadlock avoidance?', 'A state where some order lets all processes finish', 'A state with no processes', 'A state with a full disk', 'A random state', 'A', 'A safe state guarantees a sequence in which every process can obtain resources and complete.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a safe state in deadlock avoidance?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does deadlock detection differ from prevention?', 'It never allows requests', 'It allows deadlocks then finds and resolves them', 'It schedules processes', 'It formats memory', 'B', 'Detection permits deadlocks to occur and periodically checks for them, then recovers.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does deadlock detection differ from prevention?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What structure helps detect a deadlock cycle?', 'A sorted array', 'A hash table of files', 'A resource allocation graph', 'A scheduling queue', 'C', 'A resource-allocation graph models allocations and requests; a cycle may indicate deadlock.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What structure helps detect a deadlock cycle?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is one recovery method from deadlock?', 'Adding more deadlocks', 'Ignoring the system', 'Formatting the CPU', 'Aborting one or more processes to break the cycle', 'D', 'Recovery can terminate processes or preempt their resources to break the circular wait.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is one recovery method from deadlock?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is resource preemption as a recovery strategy?', 'Taking resources from a process to give to another', 'Giving all resources at once', 'Never reclaiming resources', 'Scheduling the CPU', 'A', 'Preemption forcibly reclaims resources from a process, which may be rolled back, to resolve deadlock.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is resource preemption as a recovery strategy?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can simply ignoring deadlocks sometimes be acceptable?', 'They never occur', 'If they are rare and detection costs more than restarts', 'Ignoring speeds the CPU', 'It prevents all deadlocks', 'B', 'Some systems use the ostrich approach, accepting rare deadlocks because handling them is costlier.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can simply ignoring deadlocks sometimes be acceptable?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does no-preemption as a deadlock condition mean?', 'Resources are always taken', 'Processes never hold resources', 'Resources cannot be forcibly taken from a holder', 'The CPU is preempted', 'C', 'No-preemption means a resource is released only voluntarily by the process that holds it.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does no-preemption as a deadlock condition mean?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is livelock, as distinct from deadlock?', 'Processes stop entirely', 'A single process runs', 'The CPU idles', 'Processes keep changing state but make no progress', 'D', 'In livelock processes remain active, repeatedly responding to each other, yet none advances.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is livelock, as distinct from deadlock?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does requiring resources in increasing order avoid cycles?', 'A process cannot wait for a lower-numbered resource it skipped', 'Numbers speed the CPU', 'Order removes mutual exclusion', 'It adds preemption', 'A', 'Ordered acquisition means waits only go up the ordering, so no closed cycle can form.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does requiring resources in increasing order avoid cycles?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the banker''s algorithm require processes to declare?', 'Their exact runtime', 'Their maximum resource needs in advance', 'Their thread count', 'Nothing at all', 'B', 'Each process must state its maximum demand so the system can judge whether a grant stays safe.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the banker''s algorithm require processes to declare?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens if every philosopher grabs the left fork in the dining philosophers problem?', 'They all eat at once', 'No one is hungry', 'A circular wait can deadlock them', 'Forks multiply', 'C', 'If each grabs the left fork and waits for the right, a circular wait deadlocks all philosophers.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens if every philosopher grabs the left fork in the dining philosophers problem?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What trade-off does deadlock avoidance introduce?', 'It removes all resources', 'It speeds every request', 'It ignores safety', 'Extra checks may reject safe-looking requests conservatively', 'D', 'Avoidance stays conservative to guarantee safety, sometimes delaying requests that could be granted.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What trade-off does deadlock avoidance introduce?');

  -- ---- Operating Systems / Memory Management (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Operating Systems'
    and t.topic_name = 'Memory Management';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Operating Systems', 'Memory Management';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the operating system''s memory manager do?', 'Allocate and track memory among processes', 'Schedule the CPU', 'Route packets', 'Format text', 'A', 'The memory manager assigns memory to processes and keeps track of what is in use.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the operating system''s memory manager do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is fragmentation in memory management?', 'A full disk', 'Unusable gaps of free memory', 'A fast allocation', 'A scheduling policy', 'B', 'Fragmentation leaves free memory split into pieces that cannot satisfy requests.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is fragmentation in memory management?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is external fragmentation?', 'Wasted space inside an allocation', 'A full cache', 'Free memory scattered in small non-contiguous blocks', 'A sorted heap', 'C', 'External fragmentation is free space broken into fragments too small to use for larger requests.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is external fragmentation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is internal fragmentation?', 'Scattered free blocks', 'A full disk', 'A fast lookup', 'Unused space within an allocated block', 'D', 'Internal fragmentation is the leftover space inside a fixed-size allocation that a process does not use.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is internal fragmentation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does paging divide memory into?', 'Fixed-size pages and frames', 'Variable segments only', 'Single bytes', 'Disk tracks', 'A', 'Paging splits logical memory into fixed-size pages mapped to physical frames of the same size.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does paging divide memory into?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does paging reduce external fragmentation?', 'It uses variable sizes', 'Any free frame can hold any page', 'It merges segments', 'It avoids memory', 'B', 'Because pages and frames are equal fixed sizes, any free frame fits any page, avoiding external gaps.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does paging reduce external fragmentation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a page table used for?', 'Scheduling the CPU', 'Storing files', 'Mapping virtual pages to physical frames', 'Counting threads', 'C', 'A page table records which physical frame backs each virtual page for a process.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a page table used for?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does segmentation divide a program into?', 'Equal fixed pages', 'Single words', 'Disk blocks', 'Logical segments like code, data, and stack', 'D', 'Segmentation partitions a program into variable-size logical units reflecting its structure.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does segmentation divide a program into?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a base and limit register pair protect?', 'A process''s memory from out-of-range access', 'The CPU cache', 'The disk', 'The network', 'A', 'Base and limit registers bound a process''s addresses, trapping accesses outside its region.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a base and limit register pair protect?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the role of the memory management unit (MMU)?', 'Scheduling processes', 'Translating virtual addresses to physical ones at runtime', 'Formatting disks', 'Encrypting packets', 'B', 'The MMU performs address translation and protection checks as the program runs.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the role of the memory management unit (MMU)?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does fixed-size partitioning cause internal fragmentation?', 'Partitions are variable', 'It merges free space', 'A process smaller than its partition wastes the remainder', 'It avoids waste', 'C', 'If a process does not fill its fixed partition, the unused remainder is wasted internally.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does fixed-size partitioning cause internal fragmentation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does compaction do to fragmented memory?', 'Deletes processes', 'Formats the disk', 'Schedules the CPU', 'Relocates allocations to coalesce free space', 'D', 'Compaction moves occupied blocks together so free memory forms a single larger region.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does compaction do to fragmented memory?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a logical (virtual) address?', 'An address generated by the CPU before translation', 'A physical frame number', 'A disk sector', 'A file name', 'A', 'A logical address is produced by a program and later mapped to a physical address.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a logical (virtual) address?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the first-fit allocation strategy do?', 'Uses the smallest fitting block', 'Uses the first free block large enough', 'Uses the largest block', 'Uses a random block', 'B', 'First-fit scans and allocates from the first free block that satisfies the request.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the first-fit allocation strategy do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does best-fit allocation try to do?', 'Choose the first block', 'Choose the largest block', 'Choose the smallest block that fits the request', 'Avoid allocation', 'C', 'Best-fit picks the tightest free block, aiming to leave larger blocks available.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does best-fit allocation try to do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can best-fit still cause fragmentation?', 'It uses no memory', 'It merges all blocks', 'It never fits', 'It can leave many tiny unusable remnants', 'D', 'Best-fit tends to create numerous small leftovers that accumulate as unusable fragments.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can best-fit still cause fragmentation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is swapping in memory management?', 'Moving a process between memory and disk', 'Switching threads', 'Formatting pages', 'Routing packets', 'A', 'Swapping temporarily moves a process out to disk to free memory and back in later.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is swapping in memory management?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a frame refer to in paging?', 'A logical segment', 'A fixed-size block of physical memory', 'A disk track', 'A page table entry only', 'B', 'A frame is a fixed-size unit of physical memory that holds one page.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a frame refer to in paging?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is address translation done in hardware?', 'Software is faster', 'It avoids the CPU', 'It must be fast for every memory access', 'It formats memory', 'C', 'Since translation happens on every access, dedicated hardware keeps it fast.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is address translation done in hardware?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What protection does separate address spaces provide?', 'Shared memory for all', 'Faster CPUs', 'No protection', 'One process cannot access another''s memory directly', 'D', 'Distinct address spaces isolate processes so they cannot read or corrupt each other''s memory.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What protection does separate address spaces provide?');

  -- ---- Operating Systems / Virtual Memory (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Operating Systems'
    and t.topic_name = 'Virtual Memory';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Operating Systems', 'Virtual Memory';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is virtual memory?', 'An abstraction giving processes more address space than physical RAM', 'The CPU cache', 'A disk partition only', 'A scheduling queue', 'A', 'Virtual memory lets programs use a large logical address space backed by RAM and disk.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is virtual memory?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a page fault?', 'A disk format', 'A trap when accessing a page not in physical memory', 'A fast cache hit', 'A scheduling event', 'B', 'A page fault occurs when a referenced page is not resident, prompting the OS to load it.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a page fault?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does demand paging do?', 'Loads the whole program at once', 'Avoids the disk', 'Loads pages into memory only when accessed', 'Formats pages', 'C', 'Demand paging brings pages in lazily on first access rather than loading everything upfront.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does demand paging do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is thrashing?', 'Fast execution', 'A full cache', 'A sorted page table', 'Excessive paging that stalls useful work', 'D', 'Thrashing happens when processes spend more time paging than executing, collapsing throughput.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is thrashing?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a page replacement algorithm decide?', 'Which resident page to evict on a fault', 'Which process to schedule', 'How to format disk', 'Which packet to route', 'A', 'When memory is full, a replacement algorithm selects a victim page to evict for an incoming page.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a page replacement algorithm decide?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the optimal (OPT) replacement policy require?', 'No information', 'Knowledge of future references', 'The page table only', 'The disk size', 'B', 'OPT evicts the page used furthest in the future, requiring unavailable future knowledge, so it is a benchmark.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the optimal (OPT) replacement policy require?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does the LRU replacement policy choose a victim?', 'Evicts the most recently used page', 'Evicts a random page always', 'Evicts the least recently used page', 'Evicts the first loaded page', 'C', 'LRU approximates OPT by removing the page that has gone unused for the longest time.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does the LRU replacement policy choose a victim?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What anomaly can FIFO page replacement exhibit?', 'Faults always decrease with frames', 'No faults ever', 'Faster CPU', 'More frames can increase faults (Belady''s anomaly)', 'D', 'Belady''s anomaly is FIFO''s counterintuitive behavior where adding frames raises page faults for some patterns.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What anomaly can FIFO page replacement exhibit?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What hardware speeds up virtual-to-physical translation?', 'The translation lookaside buffer (TLB)', 'The disk controller', 'The network card', 'The scheduler', 'A', 'The TLB caches recent address translations to avoid repeated page-table walks.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What hardware speeds up virtual-to-physical translation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a TLB miss?', 'A disk crash', 'The translation is not cached and must be looked up', 'A full cache', 'A scheduling delay', 'B', 'On a TLB miss the system consults the page table to find the translation, which is slower.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a TLB miss?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the working set of a process represent?', 'All pages ever loaded', 'The disk size', 'The set of pages it actively uses in a time window', 'The CPU registers', 'C', 'The working set is the collection of pages a process references during a recent interval.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the working set of a process represent?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why keep a process''s working set in memory?', 'To fill the disk', 'To slow the CPU', 'To remove pages', 'To avoid excessive page faults and thrashing', 'D', 'Holding the working set resident minimizes faults, keeping the process running smoothly.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why keep a process''s working set in memory?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a dirty (modified) page require on eviction?', 'Writing it back to disk before reuse', 'Immediate deletion', 'No action', 'A CPU reset', 'A', 'A dirty page has unsaved changes and must be written to backing store before its frame is reused.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a dirty (modified) page require on eviction?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the benefit of a larger page size?', 'More internal fragmentation only', 'Smaller page tables and fewer faults for sequential access', 'No benefit', 'Slower translation', 'B', 'Larger pages reduce page-table entries and faults for contiguous access, though they can waste more space.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the benefit of a larger page size?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does copy-on-write optimize?', 'Immediate copying always', 'Disk formatting', 'Sharing pages until one process writes', 'Thread scheduling', 'C', 'Copy-on-write lets processes share pages read-only and copies a page only when it is first modified.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does copy-on-write optimize?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is accessing a page on disk much slower than in RAM?', 'Disk is faster', 'RAM is on disk', 'They are equal', 'Disk access latency is orders of magnitude higher', 'D', 'Secondary storage is far slower than memory, so a page fault that hits disk adds large delay.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is accessing a page on disk much slower than in RAM?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the second-chance (clock) algorithm?', 'A FIFO variant that spares recently referenced pages', 'A random policy', 'An LRU exact copy', 'A disk scheduler', 'A', 'The clock algorithm approximates LRU by giving pages with a set reference bit a second chance before eviction.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the second-chance (clock) algorithm?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a valid/invalid bit in a page table entry indicate?', 'The page color', 'Whether the page is currently in memory', 'The disk speed', 'The CPU core', 'B', 'The valid bit shows whether a page is resident; an access to an invalid page triggers a fault.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a valid/invalid bit in a page table entry indicate?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How can increasing the degree of multiprogramming lead to thrashing?', 'It removes all processes', 'It frees the disk', 'Too many processes shrink each working set below need', 'It speeds translation', 'C', 'With too many processes, each gets too few frames to hold its working set, causing heavy paging.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How can increasing the degree of multiprogramming lead to thrashing?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What problem does virtual memory solve for programmers?', 'Programs run without a CPU', 'No files are needed', 'Disks become faster', 'Programs need not fit entirely in physical RAM', 'D', 'Virtual memory frees programmers from manually fitting a program into limited physical memory.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What problem does virtual memory solve for programmers?');

  -- ---- Operating Systems / File Systems (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Operating Systems'
    and t.topic_name = 'File Systems';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Operating Systems', 'File Systems';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a file system manage?', 'How data is stored and organized on storage devices', 'CPU scheduling', 'Network routing', 'Thread creation', 'A', 'A file system organizes files and directories and tracks where their data resides on storage.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a file system manage?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a directory?', 'A single data block', 'A structure mapping names to files', 'A CPU register', 'A network port', 'B', 'A directory associates human-readable names with files and other directories.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a directory?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an inode (or file control block) store?', 'The file name only', 'The directory tree', 'File metadata and block locations', 'The CPU state', 'C', 'An inode holds metadata such as size, permissions, timestamps, and pointers to data blocks.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an inode (or file control block) store?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is contiguous allocation of file blocks?', 'Scattering blocks randomly', 'Using a linked chain', 'Using an index block', 'Storing a file in consecutive blocks', 'D', 'Contiguous allocation places a file''s blocks back to back, giving fast sequential access.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is contiguous allocation of file blocks?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What drawback does contiguous allocation have?', 'External fragmentation and growth difficulty', 'No sequential access', 'Random layout', 'Slow reads only', 'A', 'Contiguous files suffer fragmentation and are hard to grow when neighboring blocks are taken.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What drawback does contiguous allocation have?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does linked allocation store a file?', 'In one contiguous run', 'Each block points to the next block', 'With an index block', 'In a hash table', 'B', 'Linked allocation chains blocks via pointers, avoiding external fragmentation but hurting random access.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does linked allocation store a file?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is random access slow with linked allocation?', 'Blocks are contiguous', 'It uses an index', 'Reaching block k requires following k pointers', 'It is actually fast', 'C', 'Without an index, locating an arbitrary block means traversing the chain from the start.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is random access slow with linked allocation?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does indexed allocation use?', 'A single pointer', 'A contiguous run only', 'A hash of names', 'An index block listing a file''s data blocks', 'D', 'Indexed allocation keeps an index block of pointers, enabling direct access to any data block.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does indexed allocation use?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the purpose of file permissions?', 'Controlling who can read, write, or execute a file', 'Speeding the disk', 'Scheduling the CPU', 'Routing packets', 'A', 'Permissions restrict access to files based on users and their rights.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the purpose of file permissions?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a path like /home/user/file.txt describe?', 'A CPU instruction', 'A location within the directory hierarchy', 'A network route', 'A memory frame', 'B', 'A path names a file by its position in the tree of directories.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a path like /home/user/file.txt describe?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a hard link?', 'A copy of the file data', 'A network link', 'Another directory entry pointing to the same inode', 'A symbolic path', 'C', 'A hard link is an additional name referring to the same underlying inode and data.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a hard link?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does a symbolic (soft) link differ from a hard link?', 'It copies the data', 'It is a network link', 'It cannot be removed', 'It stores a path to another file rather than the inode', 'D', 'A symbolic link contains a path to the target; if the target is removed, the link dangles.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does a symbolic (soft) link differ from a hard link?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a file system journal provide?', 'Recovery to a consistent state after a crash', 'Faster CPUs', 'More RAM', 'Network security', 'A', 'A journal logs intended changes so the file system can recover consistency after failures.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a file system journal provide?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a block (or cluster) in a file system?', 'A single bit', 'The smallest unit of allocation on disk', 'A directory', 'A CPU cache line', 'B', 'Storage is allocated in fixed-size blocks, the file system''s basic allocation unit.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a block (or cluster) in a file system?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can small files waste space with large block sizes?', 'Blocks shrink to fit', 'Files cannot be small', 'A file smaller than a block still consumes a whole block', 'Blocks are free', 'C', 'A tiny file occupies at least one full block, wasting the unused remainder (internal fragmentation).', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can small files waste space with large block sizes?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does mounting a file system do?', 'Formats the disk', 'Deletes files', 'Schedules the CPU', 'Attaches it into the existing directory tree', 'D', 'Mounting makes a file system accessible at a point within the overall directory hierarchy.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does mounting a file system do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a free-space management structure for?', 'Tracking which blocks are available', 'Scheduling processes', 'Routing packets', 'Encrypting files', 'A', 'The file system tracks free blocks, often with a bitmap or free list, to allocate new data.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a free-space management structure for?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a file''s metadata include?', 'The CPU type', 'Attributes like size, owner, and timestamps', 'The network address', 'The page table', 'B', 'Metadata describes the file, including its size, ownership, permissions, and modification times.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a file''s metadata include?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why do many file systems cache recently used blocks in memory?', 'To fill the disk', 'To slow reads', 'To reduce slow disk accesses', 'To remove files', 'C', 'A buffer cache keeps hot blocks in RAM so repeated accesses avoid slow disk reads.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why do many file systems cache recently used blocks in memory?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a bitmap for free space represent?', 'The file contents', 'The directory names', 'The CPU registers', 'Each bit marks a block as free or used', 'D', 'A free-space bitmap uses one bit per block to record whether that block is allocated.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a bitmap for free space represent?');

  -- ---- Computer Networks / OSI and TCP/IP Models (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Computer Networks'
    and t.topic_name = 'OSI and TCP/IP Models';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Computer Networks', 'OSI and TCP/IP Models';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How many layers does the OSI reference model define?', 'Seven', 'Four', 'Five', 'Three', 'A', 'The OSI model organizes networking into seven layers from physical up to application.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How many layers does the OSI reference model define?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which OSI layer is responsible for end-to-end delivery and reliability?', 'Physical', 'Transport', 'Data link', 'Session', 'B', 'The transport layer provides end-to-end delivery, including reliability features like those in TCP.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which OSI layer is responsible for end-to-end delivery and reliability?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the physical layer deal with?', 'Routing packets', 'Application data formats', 'Transmitting raw bits over a medium', 'Session management', 'C', 'The physical layer handles the electrical, optical, or radio transmission of raw bits.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the physical layer deal with?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which layer of the TCP/IP model corresponds roughly to OSI layers 5-7?', 'Internet', 'Link', 'Transport', 'Application', 'D', 'The TCP/IP application layer encompasses the OSI session, presentation, and application layers.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which layer of the TCP/IP model corresponds roughly to OSI layers 5-7?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is encapsulation in layered networking?', 'Each layer wraps data with its own header', 'Removing all headers', 'Sorting packets', 'Encrypting the payload only', 'A', 'As data descends the stack, each layer adds its header, encapsulating the layer above.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is encapsulation in layered networking?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the network layer primarily provide?', 'Bit transmission', 'Logical addressing and routing between networks', 'Reliable byte streams', 'Data presentation', 'B', 'The network layer addresses hosts logically and routes packets across interconnected networks.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the network layer primarily provide?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which layer ensures node-to-node delivery over a single link?', 'Transport', 'Application', 'Data link', 'Network', 'C', 'The data link layer frames bits and delivers them between directly connected nodes.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which layer ensures node-to-node delivery over a single link?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a protocol data unit at the transport layer commonly called?', 'A frame', 'A packet', 'A bit', 'A segment', 'D', 'Transport-layer data units are called segments (TCP) or datagrams (UDP).', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a protocol data unit at the transport layer commonly called?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why are layered models useful?', 'They separate concerns so layers can evolve independently', 'They slow the network', 'They remove protocols', 'They merge all functions', 'A', 'Layering isolates functionality, letting each layer be designed and changed without affecting others.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why are layered models useful?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the presentation layer handle in OSI?', 'Routing', 'Data representation such as encoding and encryption', 'Bit signaling', 'Reliable delivery', 'B', 'The presentation layer translates data formats, including encoding, compression, and encryption.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the presentation layer handle in OSI?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How many layers does the classic TCP/IP model have?', 'Seven', 'Five', 'Four', 'Two', 'C', 'The TCP/IP model is commonly described with four layers: link, internet, transport, and application.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How many layers does the classic TCP/IP model have?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What unit does the network layer work with?', 'Frames', 'Bits', 'Segments', 'Packets', 'D', 'The network layer handles packets, routing them based on logical addresses.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What unit does the network layer work with?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does de-encapsulation do at the receiver?', 'Each layer strips its header as data moves up', 'Adds headers going up', 'Encrypts the payload', 'Routes packets', 'A', 'On receipt, each layer removes its corresponding header before passing data upward.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does de-encapsulation do at the receiver?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which layer manages sessions and dialogue control in OSI?', 'Transport', 'Session', 'Network', 'Physical', 'B', 'The session layer establishes, manages, and terminates communication sessions.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which layer manages sessions and dialogue control in OSI?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does the application layer not include the actual application?', 'Applications run in the physical layer', 'It stores files', 'It provides protocols applications use to communicate', 'It routes packets', 'C', 'The application layer defines protocols like HTTP that programs use, not the programs themselves.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does the application layer not include the actual application?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What distinguishes a connectionless from a connection-oriented service?', 'Connectionless always guarantees order', 'Connection-oriented is unreliable', 'They are identical', 'Connectionless sends without establishing a session first', 'D', 'Connectionless service sends independent units without setup; connection-oriented establishes state first.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What distinguishes a connectionless from a connection-oriented service?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the main role of headers added at each layer?', 'Carry control information for that layer''s peer', 'Store user passwords', 'Increase payload size only', 'Encrypt everything', 'A', 'Each layer''s header conveys addressing and control data to the matching layer at the destination.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the main role of headers added at each layer?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which TCP/IP layer maps to the OSI data link and physical layers?', 'Transport', 'Link (network access)', 'Application', 'Internet', 'B', 'The TCP/IP link layer combines the OSI physical and data link responsibilities.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which TCP/IP layer maps to the OSI data link and physical layers?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the transport layer use to deliver data to the right application?', 'MAC addresses', 'Frame checksums', 'Port numbers', 'Routing tables', 'C', 'Port numbers identify the application endpoint so the transport layer delivers data correctly.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the transport layer use to deliver data to the right application?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does the OSI model remain useful despite TCP/IP being dominant in practice?', 'It replaced TCP/IP', 'It defines all real protocols', 'It has no layers', 'It is a clear teaching and reference framework', 'D', 'The OSI model offers a well-defined conceptual framework for understanding and discussing networking.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does the OSI model remain useful despite TCP/IP being dominant in practice?');

  -- ---- Computer Networks / Data Link Layer and Switching (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Computer Networks'
    and t.topic_name = 'Data Link Layer and Switching';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Computer Networks', 'Data Link Layer and Switching';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a MAC address?', 'A hardware address identifying a network interface', 'A logical IP address', 'A port number', 'A domain name', 'A', 'A MAC address is a hardware identifier assigned to a network interface for link-layer delivery.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a MAC address?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does framing do at the data link layer?', 'Routes packets', 'Groups bits into structured frames', 'Assigns IP addresses', 'Encrypts sessions', 'B', 'Framing delimits the bit stream into frames with headers and trailers for delivery and error checks.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does framing do at the data link layer?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does a switch decide where to forward a frame?', 'By the IP address', 'By the port number', 'By looking up the destination MAC in its table', 'Randomly', 'C', 'A switch forwards frames based on learned MAC-address-to-port mappings.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does a switch decide where to forward a frame?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does a switch build its MAC address table?', 'By asking a router', 'From DNS', 'From the IP header', 'By learning source addresses of incoming frames', 'D', 'A switch records the source MAC and incoming port of frames to learn where devices are.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does a switch build its MAC address table?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a switch do with a frame for an unknown destination MAC?', 'Floods it out all ports except the source', 'Drops it', 'Routes it by IP', 'Returns it to sender', 'A', 'If the destination is unknown, the switch floods the frame to all ports except where it arrived.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a switch do with a frame for an unknown destination MAC?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the purpose of a frame check sequence?', 'Encrypting the frame', 'Detecting transmission errors in a frame', 'Routing the frame', 'Assigning a MAC', 'B', 'The FCS carries a checksum (often CRC) so the receiver can detect corrupted frames.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the purpose of a frame check sequence?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a collision domain?', 'A routing table', 'An IP subnet', 'A network segment where frames can collide', 'A DNS zone', 'C', 'A collision domain is a region where simultaneous transmissions interfere; switches separate them per port.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a collision domain?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does a switch differ from a hub?', 'A switch repeats to all ports', 'A hub learns MACs', 'They are identical', 'A switch forwards selectively; a hub repeats to all ports', 'D', 'A switch forwards frames only to the needed port, while a hub blindly repeats to every port.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does a switch differ from a hub?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What problem does the spanning tree protocol prevent?', 'Switching loops in redundant topologies', 'IP address conflicts', 'DNS failures', 'Routing loops only', 'A', 'STP blocks redundant links to prevent loops that would otherwise cause broadcast storms.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What problem does the spanning tree protocol prevent?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a broadcast domain?', 'A single switch port', 'The set of devices a broadcast frame reaches', 'A routing table', 'A TCP connection', 'B', 'A broadcast domain includes all devices that receive a broadcast; routers bound it, switches extend it.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a broadcast domain?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a VLAN do?', 'Routes between networks', 'Assigns IP addresses', 'Logically segments a switched network', 'Resolves domain names', 'C', 'A VLAN partitions a physical switch into separate logical broadcast domains.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a VLAN do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the role of the data link layer''s address versus the network address?', 'They are the same', 'Link address is global', 'Network address is per-hop', 'Link address is local; network address is end-to-end', 'D', 'MAC addresses handle delivery on a local link, while IP addresses identify endpoints across networks.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the role of the data link layer''s address versus the network address?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does half-duplex communication mean?', 'Devices can send or receive but not simultaneously', 'Both send at once', 'Only receiving is possible', 'No communication', 'A', 'Half-duplex alternates transmission direction, so a device cannot send and receive at the same time.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does half-duplex communication mean?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is CSMA/CD associated with?', 'Routing packets', 'Detecting collisions on shared Ethernet media', 'Resolving names', 'Assigning ports', 'B', 'CSMA/CD senses the medium and detects collisions on legacy shared Ethernet, then backs off.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is CSMA/CD associated with?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why do switches reduce collisions compared with hubs?', 'They repeat all frames', 'They slow the network', 'Each port is its own collision domain', 'They use IP addresses', 'C', 'By giving each port a separate collision domain, switches largely eliminate collisions.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why do switches reduce collisions compared with hubs?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a frame''s destination address field specify?', 'The sender''s IP', 'The TCP port', 'The DNS name', 'The intended recipient''s MAC address', 'D', 'The destination MAC field tells the link layer which interface should receive the frame.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a frame''s destination address field specify?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is unicast delivery?', 'Sending to a single specific recipient', 'Sending to all devices', 'Sending to a group', 'Sending to no one', 'A', 'Unicast targets one recipient, unlike broadcast (all) or multicast (a group).', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is unicast delivery?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a switch do with a frame destined for a known port?', 'Floods all ports', 'Forwards it only out that port', 'Drops it', 'Routes it by IP', 'B', 'When the destination MAC is known, the switch forwards the frame solely to the mapped port.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a switch do with a frame destined for a known port?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a broadcast frame''s destination address?', 'The sender''s address', 'A random MAC', 'A special all-ones address reaching every device', 'A unicast MAC', 'C', 'A broadcast uses the all-ones MAC address so every device on the segment receives the frame.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a broadcast frame''s destination address?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is the data link layer split into LLC and MAC sublayers in some models?', 'To route packets', 'To assign IPs', 'To resolve names', 'To separate link control from media access', 'D', 'The LLC manages link control while the MAC sublayer governs access to the shared medium.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is the data link layer split into LLC and MAC sublayers in some models?');

  -- ---- Computer Networks / IP Addressing and Subnetting (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Computer Networks'
    and t.topic_name = 'IP Addressing and Subnetting';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Computer Networks', 'IP Addressing and Subnetting';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How many bits make up an IPv4 address?', '32', '64', '128', '16', 'A', 'An IPv4 address is 32 bits, usually written as four decimal octets.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How many bits make up an IPv4 address?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How many bits make up an IPv6 address?', '32', '128', '64', '256', 'B', 'IPv6 uses 128-bit addresses, vastly expanding the available address space.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How many bits make up an IPv6 address?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a subnet mask do?', 'Encrypts the address', 'Routes packets', 'Separates the network and host portions of an address', 'Assigns ports', 'C', 'A subnet mask marks which bits identify the network versus the host within an IP address.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a subnet mask do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the /24 in CIDR notation mean?', 'There are 24 hosts', '24 subnets exist', 'The address is 24 bits', 'The first 24 bits are the network prefix', 'D', 'A /24 prefix means 24 network bits, leaving 8 bits for host addresses.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the /24 in CIDR notation mean?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How many usable host addresses does a /24 IPv4 subnet provide?', '254', '256', '255', '253', 'A', 'A /24 has 256 addresses, minus the network and broadcast addresses, leaving 254 usable hosts.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How many usable host addresses does a /24 IPv4 subnet provide?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What are private IP address ranges used for?', 'Public web servers', 'Internal networks not routed on the public Internet', 'DNS roots', 'MAC addressing', 'B', 'Private ranges like 10.0.0.0/8 are for internal use and are not routed publicly.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What are private IP address ranges used for?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does subnetting allow an organization to do?', 'Merge all networks', 'Remove IP addresses', 'Divide a network into smaller logical subnets', 'Assign MAC addresses', 'C', 'Subnetting partitions an address block into smaller subnets for structure and efficiency.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does subnetting allow an organization to do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the network address of a subnet?', 'The highest address', 'A random host', 'The gateway only', 'The lowest address with all host bits zero', 'D', 'The network address has all host bits set to zero and identifies the subnet itself.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the network address of a subnet?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the broadcast address of a subnet?', 'The address with all host bits set to one', 'The first host address', 'The network address', 'A private gateway', 'A', 'The broadcast address has all host bits one and reaches every host on the subnet.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the broadcast address of a subnet?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why was NAT widely adopted with IPv4?', 'It increases IPv4 bits', 'It lets many hosts share fewer public addresses', 'It replaces DNS', 'It removes routing', 'B', 'Network Address Translation maps many private addresses to one or few public ones, easing IPv4 scarcity.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why was NAT widely adopted with IPv4?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does borrowing host bits for the network portion accomplish?', 'Adds more hosts per subnet', 'Removes the mask', 'Creates more subnets with fewer hosts each', 'Changes the IP version', 'C', 'Taking bits from the host part increases the number of subnets while reducing hosts per subnet.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does borrowing host bits for the network portion accomplish?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the loopback address 127.0.0.1 refer to?', 'The default gateway', 'A broadcast', 'The DNS server', 'The local host itself', 'D', 'The loopback address refers back to the local machine, used for self-communication and testing.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the loopback address 127.0.0.1 refer to?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What notation combines an address and prefix length?', 'CIDR notation like 192.168.1.0/24', 'A MAC address', 'A port number', 'A hostname', 'A', 'CIDR notation appends a slash and prefix length to express the network portion.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What notation combines an address and prefix length?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How many addresses does a /30 subnet contain?', '2', '4', '8', '16', 'B', 'A /30 leaves 2 host bits, so 2^2 = 4 total addresses, 2 of them usable for hosts.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How many addresses does a /30 subnet contain?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the purpose of a default gateway?', 'Resolving domain names', 'Assigning MACs', 'Forwarding traffic destined outside the local subnet', 'Encrypting packets', 'C', 'Hosts send off-subnet traffic to the default gateway, which routes it toward other networks.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the purpose of a default gateway?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does DHCP provide to hosts?', 'Domain name resolution only', 'MAC addresses', 'Routing tables', 'Automatic IP address configuration', 'D', 'DHCP leases IP addresses and related settings to hosts automatically.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does DHCP provide to hosts?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does IPv6 largely remove the need for NAT?', 'Its huge address space gives every device a public address', 'It has fewer addresses', 'It bans routing', 'It uses MAC addresses', 'A', 'IPv6''s enormous address space allows globally unique addresses, reducing reliance on NAT.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does IPv6 largely remove the need for NAT?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What class of IPv4 address begins with 10.?', 'A public web address', 'A private address', 'A multicast address', 'A loopback address', 'B', 'The 10.0.0.0/8 block is a private range reserved for internal networks.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What class of IPv4 address begins with 10.?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a longer subnet prefix imply about host capacity?', 'More hosts per subnet', 'No change in hosts', 'Fewer hosts per subnet', 'More subnets with more hosts', 'C', 'A longer prefix leaves fewer host bits, so each subnet holds fewer hosts.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a longer subnet prefix imply about host capacity?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What distinguishes a public from a private IP address?', 'Private addresses are globally routable', 'They are identical', 'Public addresses are only local', 'Public addresses are globally routable on the Internet', 'D', 'Public addresses are routable on the Internet, while private ones are confined to internal networks.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What distinguishes a public from a private IP address?');

  -- ---- Computer Networks / Routing (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Computer Networks'
    and t.topic_name = 'Routing';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Computer Networks', 'Routing';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a router do?', 'Forwards packets between different networks', 'Switches frames within a LAN', 'Resolves domain names', 'Assigns MAC addresses', 'A', 'A router connects networks and forwards packets toward their destination based on IP addresses.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a router do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a routing table contain?', 'MAC-to-port mappings', 'Destinations and the next hop or interface to reach them', 'DNS records', 'TCP ports', 'B', 'A routing table maps destination networks to the next hop or outgoing interface.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a routing table contain?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the difference between static and dynamic routing?', 'Static adapts automatically', 'Dynamic is manual', 'Static is manually set; dynamic adapts via protocols', 'They are identical', 'C', 'Static routes are configured by hand, while dynamic routing protocols learn and update routes automatically.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the difference between static and dynamic routing?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What metric does a distance-vector protocol like RIP use?', 'Link bandwidth only', 'Port numbers', 'MAC addresses', 'Hop count', 'D', 'RIP chooses routes by the number of hops to the destination.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What metric does a distance-vector protocol like RIP use?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What information do link-state protocols like OSPF share?', 'The state of each router''s links to build a full map', 'Only hop counts', 'DNS records', 'MAC tables', 'A', 'Link-state routers flood link information so each builds a complete topology and computes shortest paths.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What information do link-state protocols like OSPF share?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the default route used for?', 'Only local traffic', 'Destinations not matched by more specific routes', 'DNS queries', 'Broadcasts', 'B', 'The default route forwards packets whose destination has no more specific entry.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the default route used for?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does longest-prefix matching determine?', 'The fastest link', 'The MAC address', 'Which routing entry is most specific for a destination', 'The TCP port', 'C', 'Routers select the entry with the longest matching network prefix for the destination address.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does longest-prefix matching determine?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can routing loops occur with poorly configured distance-vector routing?', 'Links never change', 'Hop counts are exact', 'Loops are impossible', 'Routers may advertise stale paths to each other', 'D', 'Slow convergence can cause routers to keep pointing at each other for a destination, forming a loop.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can routing loops occur with poorly configured distance-vector routing?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is convergence in routing?', 'All routers reaching a consistent view of the topology', 'A single router failing', 'Packet encryption', 'Address assignment', 'A', 'Convergence is when routers have updated and agree on the network''s routes after a change.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is convergence in routing?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an autonomous system represent?', 'A single host', 'A network under one administrative routing policy', 'A DNS zone', 'A switch port', 'B', 'An autonomous system is a collection of networks under common administrative control and routing policy.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an autonomous system represent?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which protocol routes between autonomous systems on the Internet?', 'RIP', 'OSPF', 'BGP', 'ARP', 'C', 'BGP is the inter-domain protocol that exchanges routing information between autonomous systems.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which protocol routes between autonomous systems on the Internet?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the time-to-live field in an IP packet prevent?', 'Address conflicts', 'DNS failures', 'Port exhaustion', 'Packets looping forever', 'D', 'TTL decrements at each hop and discards the packet at zero, limiting how long it can circulate.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the time-to-live field in an IP packet prevent?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a router do when a packet''s TTL reaches zero?', 'Discards it and may send an error back', 'Forwards it anyway', 'Doubles the TTL', 'Stores it forever', 'A', 'A router drops a TTL-expired packet, often returning an ICMP time-exceeded message.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a router do when a packet''s TTL reaches zero?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the next hop in a routing decision?', 'The source host', 'The adjacent router or destination to forward to', 'The DNS server', 'The final MAC', 'B', 'The next hop is the immediate device the router sends the packet to on its way to the destination.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the next hop in a routing decision?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why do administrators use route metrics?', 'To assign MAC addresses', 'To resolve names', 'To choose among multiple possible paths', 'To encrypt data', 'C', 'Metrics let routing protocols prefer better paths based on cost, hops, or bandwidth.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why do administrators use route metrics?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does ICMP provide in relation to routing?', 'Reliable data streams', 'Name resolution', 'Address leasing', 'Control and error messages like unreachable or time-exceeded', 'D', 'ICMP carries diagnostic and error messages that support IP, used by tools like ping and traceroute.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does ICMP provide in relation to routing?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a stub network?', 'A network with only one connection to the rest', 'A core backbone', 'A DNS root', 'A broadcast domain', 'A', 'A stub network has a single path to other networks, so it needs minimal routing.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a stub network?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What problem does split horizon address in distance-vector routing?', 'Encrypting routes', 'Advertising a route back toward its source', 'Assigning IPs', 'Resolving names', 'B', 'Split horizon avoids sending a learned route back out the interface it came from, reducing loops.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What problem does split horizon address in distance-vector routing?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does forwarding differ from routing in a router?', 'They are identical', 'Routing moves packets', 'Forwarding moves a packet; routing computes the paths', 'Forwarding builds tables', 'C', 'Routing builds and maintains the tables, while forwarding is the per-packet action of sending it onward.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does forwarding differ from routing in a router?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is hierarchical addressing important for scalable routing?', 'It removes all routes', 'It slows routing', 'It requires MAC addresses', 'It lets routers aggregate many destinations into one entry', 'D', 'Hierarchy allows route aggregation, keeping routing tables manageable as networks grow.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is hierarchical addressing important for scalable routing?');

  -- ---- Computer Networks / Transport Layer Protocols (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Computer Networks'
    and t.topic_name = 'Transport Layer Protocols';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Computer Networks', 'Transport Layer Protocols';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does TCP provide that UDP does not?', 'Reliable, ordered delivery with retransmission', 'Lower overhead only', 'Connectionless sending', 'No ports', 'A', 'TCP guarantees reliable, in-order delivery through acknowledgments and retransmission.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does TCP provide that UDP does not?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is UDP best suited for?', 'Guaranteed file transfer', 'Low-latency applications tolerating some loss', 'Reliable streams', 'Ordered delivery', 'B', 'UDP''s minimal overhead suits latency-sensitive uses like streaming or gaming that tolerate loss.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is UDP best suited for?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the TCP three-way handshake establish?', 'A routing table', 'A DNS record', 'A connection with synchronized sequence numbers', 'A MAC mapping', 'C', 'The SYN, SYN-ACK, ACK exchange sets up a connection and agrees on initial sequence numbers.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the TCP three-way handshake establish?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What role do port numbers play at the transport layer?', 'Identify the network', 'Resolve names', 'Store routes', 'Identify the sending and receiving applications', 'D', 'Ports distinguish application endpoints so data reaches the correct process.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What role do port numbers play at the transport layer?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a TCP acknowledgment number indicate?', 'The next byte the receiver expects', 'The sender''s port', 'The route taken', 'The MAC address', 'A', 'The ACK number tells the sender which byte the receiver expects next, confirming received data.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a TCP acknowledgment number indicate?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is TCP flow control for?', 'Routing packets', 'Preventing a fast sender from overwhelming the receiver', 'Resolving names', 'Assigning ports', 'B', 'Flow control uses a receiver-advertised window to pace the sender to the receiver''s capacity.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is TCP flow control for?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does TCP congestion control respond to?', 'DNS failures', 'MAC changes', 'Signs of network congestion like loss', 'Port numbers', 'C', 'Congestion control adjusts the sending rate based on perceived network congestion to avoid collapse.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does TCP congestion control respond to?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is UDP described as connectionless?', 'It always sets up a connection', 'It guarantees order', 'It uses no IP', 'It sends datagrams without establishing a session', 'D', 'UDP sends independent datagrams with no handshake or connection state.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is UDP described as connectionless?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the TCP sequence number enable?', 'Ordering bytes and detecting missing data', 'Routing packets', 'Resolving names', 'Assigning MACs', 'A', 'Sequence numbers let the receiver reassemble bytes in order and detect gaps.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the TCP sequence number enable?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens when a TCP segment is lost?', 'It is ignored permanently', 'It is retransmitted after a timeout or duplicate ACKs', 'The connection resets always', 'UDP resends it', 'B', 'TCP detects loss via timeouts or duplicate ACKs and retransmits the missing data.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens when a TCP segment is lost?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the purpose of the TCP window size?', 'Sets the MAC address', 'Chooses the route', 'Limits unacknowledged data in flight', 'Resolves the hostname', 'C', 'The window bounds how much data can be sent before requiring acknowledgment, enabling flow control.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the purpose of the TCP window size?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does UDP have lower overhead than TCP?', 'It adds more headers', 'It encrypts everything', 'It uses larger windows', 'It omits connection setup, ordering, and acknowledgments', 'D', 'UDP skips the mechanisms TCP uses for reliability, so its header and processing are lighter.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does UDP have lower overhead than TCP?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the TCP FIN flag signal?', 'A sender has finished sending data', 'A new connection', 'A reset', 'A retransmission', 'A', 'FIN begins the orderly connection teardown, indicating the sender has no more data.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the TCP FIN flag signal?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does slow start do in TCP?', 'Starts at maximum speed', 'Gradually increases the sending rate from a small window', 'Stops all sending', 'Ignores congestion', 'B', 'Slow start probes capacity by growing the congestion window exponentially until a threshold or loss.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does slow start do in TCP?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is multiplexing at the transport layer?', 'Combining physical links', 'Encrypting sessions', 'Many applications sharing the network via ports', 'Routing packets', 'C', 'Multiplexing lets multiple application flows share the host''s network using distinct port numbers.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is multiplexing at the transport layer?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why might a real-time voice call prefer UDP?', 'It needs guaranteed delivery', 'It requires ordering', 'It avoids ports', 'Timely delivery matters more than retransmitting lost data', 'D', 'For voice, late data is useless, so UDP''s speed is preferred over TCP''s retransmissions.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why might a real-time voice call prefer UDP?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a TCP RST segment do?', 'Abruptly resets the connection', 'Opens a connection', 'Acknowledges data', 'Resizes the window', 'A', 'An RST tears down a connection immediately, often in response to an unexpected segment.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a TCP RST segment do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does well-known port 80 typically serve?', 'DNS queries', 'HTTP web traffic', 'Email delivery', 'File transfer control', 'B', 'Port 80 is the conventional port for unencrypted HTTP traffic.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does well-known port 80 typically serve?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What transport feature ensures bytes are delivered exactly once in order?', 'UDP''s datagrams', 'IP routing', 'TCP''s sequencing and acknowledgment', 'ARP resolution', 'C', 'TCP''s sequence numbers and ACKs combine to deliver a reliable, ordered byte stream.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What transport feature ensures bytes are delivered exactly once in order?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the term reliable delivery mean for TCP?', 'Data may be dropped silently', 'Order is not preserved', 'No acknowledgments are used', 'Lost data is detected and resent until acknowledged', 'D', 'Reliable delivery means TCP retransmits until the receiver acknowledges all data correctly.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the term reliable delivery mean for TCP?');

  -- ---- Computer Networks / Application Layer Protocols (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Computer Networks'
    and t.topic_name = 'Application Layer Protocols';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Computer Networks', 'Application Layer Protocols';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does DNS translate?', 'Domain names into IP addresses', 'IP addresses into MACs', 'Ports into names', 'Packets into frames', 'A', 'DNS resolves human-readable domain names into the IP addresses hosts use to connect.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does DNS translate?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What protocol do web browsers use to fetch pages?', 'SMTP', 'HTTP (or HTTPS)', 'FTP control', 'DNS', 'B', 'Browsers retrieve web resources over HTTP, or HTTPS when encrypted.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What protocol do web browsers use to fetch pages?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is HTTPS compared with HTTP?', 'A faster unencrypted HTTP', 'A mail protocol', 'HTTP secured with TLS encryption', 'A routing protocol', 'C', 'HTTPS layers HTTP over TLS, encrypting traffic and authenticating the server.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is HTTPS compared with HTTP?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does SMTP handle?', 'Fetching web pages', 'Resolving domain names', 'Routing packets', 'Sending email between servers', 'D', 'SMTP transfers outgoing email between mail servers.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does SMTP handle?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is DNS often described as a distributed hierarchy?', 'Name resolution is delegated across many servers', 'It uses one central server', 'It has no structure', 'It stores IP routes', 'A', 'DNS distributes authority across root, top-level, and authoritative servers in a hierarchy.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is DNS often described as a distributed hierarchy?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a DNS record of type A provide?', 'A mail server', 'An IPv4 address for a name', 'An IPv6 address', 'A text note', 'B', 'An A record maps a hostname to its IPv4 address.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a DNS record of type A provide?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the role of a DNS resolver?', 'Hosting web pages', 'Sending email', 'Querying servers to resolve a name for a client', 'Routing packets', 'C', 'A resolver performs the queries needed to turn a name into an address on behalf of a client.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the role of a DNS resolver?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does statelessness mean for HTTP?', 'The server remembers all requests', 'It keeps a connection forever', 'It stores client files', 'Each request is independent of previous ones', 'D', 'HTTP treats each request independently; state is maintained by other means like cookies.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does statelessness mean for HTTP?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What are cookies used for in HTTP?', 'Maintaining state such as sessions across requests', 'Routing packets', 'Resolving names', 'Encrypting the link', 'A', 'Cookies let a server associate requests with a session despite HTTP''s statelessness.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What are cookies used for in HTTP?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What port does HTTPS commonly use?', '80', '443', '25', '53', 'B', 'HTTPS traffic conventionally uses TCP port 443.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What port does HTTPS commonly use?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does FTP primarily do?', 'Resolve domain names', 'Send email', 'Transfer files between a client and server', 'Route packets', 'C', 'FTP is a protocol for uploading and downloading files between hosts.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does FTP primarily do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does caching DNS responses improve?', 'Encryption strength', 'Routing accuracy', 'MAC assignment', 'Lookup speed and reduced server load', 'D', 'Caching lets resolvers reuse recent answers, speeding lookups and easing load on authoritative servers.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does caching DNS responses improve?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a DNS TTL control?', 'How long a record may be cached', 'The packet hop limit', 'The TCP window', 'The MAC lifetime', 'A', 'A DNS record''s TTL specifies how long resolvers may cache it before re-querying.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a DNS TTL control?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is an HTTP request method like GET used for?', 'Deleting a server', 'Requesting a representation of a resource', 'Routing a packet', 'Resolving a name', 'B', 'GET asks the server for the current representation of the identified resource.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is an HTTP request method like GET used for?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a POST request typically do?', 'Only read data', 'Resolve a name', 'Submit data to be processed by the server', 'Route a packet', 'C', 'POST sends data in the request body for the server to process, such as creating a resource.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a POST request typically do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does email use separate protocols for sending and retrieving?', 'SMTP retrieves mail', 'IMAP sends mail', 'They are the same protocol', 'SMTP sends while IMAP or POP retrieve', 'D', 'Sending uses SMTP, while clients retrieve messages from a mailbox using IMAP or POP.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does email use separate protocols for sending and retrieving?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an HTTP status code in the 404 range indicate?', 'The requested resource was not found', 'Success', 'A server error', 'A redirect', 'A', 'A 404 means the server could not find the requested resource.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an HTTP status code in the 404 range indicate?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does TLS add to application protocols?', 'Faster routing', 'Encryption and server authentication', 'Name resolution', 'Port assignment', 'B', 'TLS secures a connection with encryption and certificate-based authentication beneath protocols like HTTP.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does TLS add to application protocols?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the function of a reverse DNS lookup?', 'Finding an IP for a name', 'Sending email', 'Finding a name for a given IP address', 'Routing packets', 'C', 'Reverse DNS maps an IP address back to an associated domain name.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the function of a reverse DNS lookup?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why are application-layer protocols built atop transport protocols?', 'They route packets themselves', 'They assign IP addresses', 'They replace TCP', 'They rely on transport for delivery between endpoints', 'D', 'Application protocols use TCP or UDP to carry their messages between hosts.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why are application-layer protocols built atop transport protocols?');

  -- ---- Computer Networks / Network Security Basics (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Computer Networks'
    and t.topic_name = 'Network Security Basics';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Computer Networks', 'Network Security Basics';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does encryption protect?', 'The confidentiality of data in transit or at rest', 'The routing table', 'The MAC address', 'The hop count', 'A', 'Encryption scrambles data so only authorized parties with the key can read it.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does encryption protect?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the difference between symmetric and asymmetric encryption?', 'Both use one key', 'Symmetric uses one shared key; asymmetric uses a key pair', 'Asymmetric uses no keys', 'They are identical', 'B', 'Symmetric encryption shares a single secret key, while asymmetric uses a public/private key pair.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the difference between symmetric and asymmetric encryption?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a firewall do?', 'Resolves domain names', 'Routes between autonomous systems', 'Controls traffic based on security rules', 'Assigns IP addresses', 'C', 'A firewall permits or blocks traffic according to configured rules, enforcing a security policy.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a firewall do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does authentication establish?', 'The fastest route', 'The MAC table', 'The TCP window', 'That a party is who it claims to be', 'D', 'Authentication verifies identity before granting access or trust.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does authentication establish?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the purpose of a digital signature?', 'Verifying authenticity and integrity of a message', 'Encrypting the whole network', 'Routing packets', 'Assigning ports', 'A', 'A digital signature lets a recipient confirm the sender''s identity and that the message was not altered.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the purpose of a digital signature?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a man-in-the-middle attack involve?', 'A faster connection', 'An attacker intercepting and possibly altering traffic', 'A routing update', 'A DNS cache', 'B', 'In a MITM attack, an adversary secretly relays or modifies communication between two parties.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a man-in-the-middle attack involve?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does TLS help prevent eavesdropping?', 'It speeds routing', 'It assigns MACs', 'It encrypts the data exchanged over the connection', 'It caches DNS', 'C', 'TLS encrypts the session so intercepted traffic is unreadable without the key.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does TLS help prevent eavesdropping?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a denial-of-service attack?', 'Stealing a password', 'Encrypting data', 'Resolving names', 'Overwhelming a service so legitimate users cannot use it', 'D', 'A DoS attack floods or exhausts a target''s resources to disrupt availability.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a denial-of-service attack?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a public key infrastructure provide?', 'Trusted binding of identities to public keys via certificates', 'Faster routing', 'Address leasing', 'Name resolution', 'A', 'A PKI issues and manages certificates that associate identities with public keys.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a public key infrastructure provide?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is hashing used for password storage?', 'To encrypt the network', 'To store a non-reversible representation of the password', 'To route packets', 'To speed logins only', 'B', 'Storing a salted hash means the original password is not kept, limiting exposure if the store leaks.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is hashing used for password storage?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does integrity ensure in security?', 'Data is delivered fastest', 'Data is public', 'Data has not been altered undetected', 'Data is routed', 'C', 'Integrity guarantees that data is not modified in transit or storage without detection.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does integrity ensure in security?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a certificate authority''s role?', 'Routing packets', 'Assigning IPs', 'Caching DNS', 'Issuing and vouching for digital certificates', 'D', 'A certificate authority signs certificates, letting clients trust a server''s public key.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a certificate authority''s role?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does two-factor authentication add?', 'A second independent proof of identity', 'A faster password', 'A new IP address', 'A routing metric', 'A', '2FA requires a second factor, such as a code or device, beyond the password.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does two-factor authentication add?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the principle of least privilege?', 'Granting all access by default', 'Granting only the access needed to do a task', 'Removing all access', 'Sharing all keys', 'B', 'Least privilege limits each user or process to the minimum rights required, reducing risk.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the principle of least privilege?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a VPN provide?', 'Faster DNS', 'A public IP for all', 'An encrypted tunnel over an untrusted network', 'A routing protocol', 'C', 'A VPN creates a secure, encrypted tunnel so traffic traverses untrusted networks safely.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a VPN provide?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is phishing?', 'A routing error', 'A hashing method', 'A firewall rule', 'Tricking users into revealing credentials or data', 'D', 'Phishing deceives users, often via fake messages, into disclosing sensitive information.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is phishing?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is a salt added when hashing passwords?', 'To make identical passwords hash differently and resist precomputation', 'To speed hashing', 'To encrypt the salt', 'To route the hash', 'A', 'A unique salt per password defeats precomputed rainbow tables and distinguishes identical passwords.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is a salt added when hashing passwords?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does confidentiality mean in the security triad?', 'Keeping systems available', 'Keeping information from unauthorized parties', 'Preventing data changes', 'Routing data fast', 'B', 'Confidentiality ensures only authorized parties can read protected information.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does confidentiality mean in the security triad?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an intrusion detection system do?', 'Routes packets', 'Resolves names', 'Monitors for suspicious activity and alerts', 'Assigns IP addresses', 'C', 'An IDS watches traffic or systems for signs of attacks and raises alerts.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an intrusion detection system do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why should software be kept updated for security?', 'Updates slow the network', 'Updates remove encryption', 'Updates assign IPs', 'Updates patch known vulnerabilities', 'D', 'Patching fixes discovered vulnerabilities that attackers could otherwise exploit.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why should software be kept updated for security?');

  -- ---- Web Development / HTML Fundamentals (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Web Development'
    and t.topic_name = 'HTML Fundamentals';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Web Development', 'HTML Fundamentals';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does HTML primarily define on a web page?', 'The structure and content', 'The visual styling', 'The server logic', 'The network routing', 'A', 'HTML marks up the structure and content of a page, while CSS handles styling.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does HTML primarily define on a web page?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a semantic HTML element?', 'One with no purpose', 'One that conveys meaning about its content', 'A styling-only tag', 'A script tag', 'B', 'Semantic elements like article and nav describe the role of their content, aiding accessibility and SEO.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a semantic HTML element?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the alt attribute on an image provide?', 'A larger image', 'A hyperlink', 'Alternative text for accessibility and failures', 'A CSS class', 'C', 'The alt attribute gives descriptive text used by screen readers and shown if the image fails to load.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the alt attribute on an image provide?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which element represents the most important heading?', 'h6', 'p', 'span', 'h1', 'D', 'The h1 element denotes the top-level heading; headings descend in importance to h6.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which element represents the most important heading?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why should each page typically have a single main h1?', 'It communicates the page''s primary topic clearly', 'It changes the color', 'It is required for scripts', 'It speeds the server', 'A', 'A single clear h1 helps users and assistive technology understand the page''s primary subject.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why should each page typically have a single main h1?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the anchor element with an href do?', 'Embeds an image', 'Creates a hyperlink to another resource', 'Defines a paragraph', 'Runs JavaScript only', 'B', 'An a element with href links to another page, location, or resource.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the anchor element with an href do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the purpose of a label associated with a form input?', 'It styles the input', 'It submits the form', 'It describes the input for users and accessibility', 'It validates data', 'C', 'A label names an input and, when linked, improves usability and screen-reader support.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the purpose of a label associated with a form input?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the doctype declaration at the top of an HTML document do?', 'Imports CSS', 'Runs a script', 'Defines a route', 'Tells the browser to use standards mode', 'D', 'The doctype signals the HTML version and triggers standards-compliant rendering.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the doctype declaration at the top of an HTML document do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which attribute uniquely identifies a single element on a page?', 'id', 'class', 'name', 'type', 'A', 'An id must be unique within a document and targets one specific element.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which attribute uniquely identifies a single element on a page?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does a class attribute differ from an id?', 'A class must be unique', 'A class can be shared by many elements', 'An id can repeat freely', 'They are identical', 'B', 'Classes group multiple elements, while an id identifies a single unique element.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does a class attribute differ from an id?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the meta viewport tag enable?', 'Server-side rendering', 'Form validation', 'Responsive scaling on mobile devices', 'Image compression', 'C', 'The viewport meta tag controls how the page scales across device widths, key to responsive design.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the meta viewport tag enable?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the difference between a block and an inline element?', 'Inline elements start on new lines', 'Block elements never wrap', 'They render identically', 'Block elements start on a new line and take full width', 'D', 'Block-level elements occupy their own line and full width, while inline elements flow within text.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the difference between a block and an inline element?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why use semantic elements like nav and footer instead of generic divs?', 'They improve accessibility and document meaning', 'They render faster always', 'They require no CSS', 'They run scripts', 'A', 'Semantic tags give assistive technology and search engines meaningful structure that divs lack.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why use semantic elements like nav and footer instead of generic divs?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the ol element create?', 'An unordered list', 'An ordered (numbered) list', 'A table', 'A form', 'B', 'The ol element produces a list whose items are numbered in order.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the ol element create?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the role of the head section of an HTML document?', 'Displays visible content', 'Runs the main logic', 'Holds metadata, title, and resource links', 'Stores user data', 'C', 'The head contains non-visible metadata such as the title, character set, and links to styles.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the role of the head section of an HTML document?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the required attribute on an input do?', 'Styles the field', 'Hides the field', 'Submits the form', 'Marks the field as mandatory for form submission', 'D', 'A required input must be filled before the browser allows the form to submit.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the required attribute on an input do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is nesting elements correctly important in HTML?', 'Improper nesting can cause unpredictable rendering', 'It changes the server', 'It speeds the network', 'It is purely cosmetic', 'A', 'Well-formed, properly nested markup renders consistently across browsers and parses predictably.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is nesting elements correctly important in HTML?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the table element structure?', 'A navigation menu', 'Tabular data in rows and columns', 'A single paragraph', 'A script block', 'B', 'The table element and its row and cell children organize data into a grid.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the table element structure?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the purpose of the form element?', 'Styling text', 'Importing images', 'Collecting and submitting user input', 'Defining headings', 'C', 'A form groups input controls and defines how their data is submitted to a server.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the purpose of the form element?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an input of type email add over a plain text input?', 'A larger box', 'Automatic submission', 'Server logic', 'Basic built-in validation of email format', 'D', 'An email input provides lightweight format validation and appropriate mobile keyboards.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an input of type email add over a plain text input?');

  -- ---- Web Development / CSS Layout and Styling (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Web Development'
    and t.topic_name = 'CSS Layout and Styling';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Web Development', 'CSS Layout and Styling';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the CSS box model describe?', 'Content, padding, border, and margin of an element', 'The server response', 'The DOM events', 'The network layers', 'A', 'The box model defines how content, padding, border, and margin combine to size an element.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the CSS box model describe?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the difference between margin and padding?', 'Padding is outside the border', 'Margin is space outside the border; padding is inside', 'They are identical', 'Margin is inside the content', 'B', 'Padding sits between content and border, while margin is the space outside the border.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the difference between margin and padding?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does display: flex enable?', 'A two-dimensional grid only', 'Absolute positioning', 'A flexible one-dimensional layout of items', 'Server rendering', 'C', 'Flexbox lays out items along a single axis with flexible sizing and alignment.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does display: flex enable?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does CSS Grid provide that Flexbox does not focus on?', 'One-dimensional layout only', 'No layout', 'Only text styling', 'Two-dimensional row-and-column layout', 'D', 'Grid arranges items in both rows and columns simultaneously, suiting complex two-dimensional layouts.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does CSS Grid provide that Flexbox does not focus on?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the CSS specificity of a selector determine?', 'Which conflicting rule wins', 'The load order of files', 'The server route', 'The animation speed', 'A', 'When rules conflict, the selector with higher specificity takes precedence.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the CSS specificity of a selector determine?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does an id selector generally override a class selector?', 'A class has higher specificity', 'An id has higher specificity', 'They are equal', 'Ids are ignored', 'B', 'Id selectors carry greater specificity than class selectors, so they win conflicts.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does an id selector generally override a class selector?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does position: absolute do to an element?', 'Keeps it in normal flow', 'Centers it automatically', 'Positions it relative to its nearest positioned ancestor', 'Fixes it to the viewport', 'C', 'An absolutely positioned element is removed from normal flow and placed relative to a positioned ancestor.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does position: absolute do to an element?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the purpose of the box-sizing: border-box setting?', 'Excludes content from width', 'Removes the border', 'Adds a margin', 'Includes padding and border in the element''s width', 'D', 'With border-box, the specified width includes padding and border, simplifying sizing.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the purpose of the box-sizing: border-box setting?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a CSS media query allow?', 'Applying styles based on conditions like screen width', 'Running JavaScript', 'Fetching data', 'Routing requests', 'A', 'Media queries apply styles conditionally, enabling responsive adjustments to viewport characteristics.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a CSS media query allow?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How does the cascade resolve two rules of equal specificity?', 'The earlier rule wins', 'The later rule in source order wins', 'Both are ignored', 'A random rule wins', 'B', 'With equal specificity, the rule appearing later in the stylesheet order takes effect.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How does the cascade resolve two rules of equal specificity?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the flex-grow property control?', 'The item''s color', 'The grid rows', 'How a flex item expands to fill free space', 'The z-index', 'C', 'flex-grow sets the proportion of available space a flex item should take relative to siblings.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the flex-grow property control?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the difference between relative and absolute units in CSS?', 'Both are fixed', 'Absolute units scale', 'They are identical', 'Relative units scale with context; absolute units are fixed', 'D', 'Relative units like em or % depend on context, while absolute units like px are fixed sizes.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the difference between relative and absolute units in CSS?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the z-index property affect?', 'The stacking order of overlapping elements', 'The horizontal position', 'The font size', 'The server order', 'A', 'z-index controls which positioned elements appear in front when they overlap.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the z-index property affect?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a CSS class selector target?', 'A single id', 'All elements with that class', 'The whole document', 'An attribute only', 'B', 'A class selector styles every element carrying the specified class.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a CSS class selector target?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can margins between adjacent block elements collapse?', 'They always add together', 'Margins never collapse', 'Vertical margins merge into the larger of the two', 'Padding collapses instead', 'C', 'Adjacent vertical margins collapse to the larger value rather than summing, a defined CSS behavior.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can margins between adjacent block elements collapse?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does justify-content do in a flex container?', 'Aligns items along the cross axis', 'Sets the font', 'Changes the color', 'Aligns items along the main axis', 'D', 'justify-content distributes flex items along the container''s main axis.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does justify-content do in a flex container?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a pseudo-class like :hover used for?', 'Styling an element in a particular state', 'Creating new elements', 'Running scripts', 'Fetching data', 'A', 'A pseudo-class applies styles when an element is in a state, such as being hovered.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a pseudo-class like :hover used for?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does setting width in percent do?', 'Fixes an absolute pixel width', 'Sizes the element relative to its container', 'Removes the width', 'Sets the height', 'B', 'A percentage width is computed relative to the containing block''s width.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does setting width in percent do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What advantage does an external stylesheet offer?', 'It runs faster than inline only', 'It cannot be cached', 'Styles can be reused and cached across pages', 'It mixes HTML and CSS', 'C', 'An external stylesheet centralizes styles for reuse and lets the browser cache them across pages.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What advantage does an external stylesheet offer?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does align-items control in a flex container?', 'Alignment along the main axis', 'The text color', 'The grid columns', 'Alignment of items along the cross axis', 'D', 'align-items sets how flex items align on the axis perpendicular to the main axis.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does align-items control in a flex container?');

  -- ---- Web Development / JavaScript Fundamentals (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Web Development'
    and t.topic_name = 'JavaScript Fundamentals';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Web Development', 'JavaScript Fundamentals';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the difference between let and const in JavaScript?', 'const cannot be reassigned after initialization', 'let cannot be reassigned', 'Both are reassignable', 'Neither can be declared', 'A', 'A const binding cannot be reassigned, while let allows reassignment.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the difference between let and const in JavaScript?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does === check that == does not?', 'Only type equality', 'Equality without type coercion', 'Reference order', 'Variable scope', 'B', 'Strict equality (===) compares value and type without coercion, unlike loose equality (==).', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does === check that == does not?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a closure in JavaScript?', 'A loop that never ends', 'A built-in object', 'A function that retains access to its outer scope', 'A CSS rule', 'C', 'A closure captures variables from its enclosing scope, keeping them accessible after that scope returns.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a closure in JavaScript?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the typeof operator return for an array?', 'array', 'list', 'undefined', 'object', 'D', 'Arrays are objects in JavaScript, so typeof returns "object" for them.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the typeof operator return for an array?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is hoisting?', 'Declarations being processed before code runs', 'Deleting variables', 'Sorting functions', 'Encrypting code', 'A', 'Hoisting moves declarations to the top of their scope conceptually, though let/const stay in a temporal dead zone.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is hoisting?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can var behave unexpectedly in loops compared with let?', 'var is block-scoped', 'var is function-scoped, so it is shared across iterations', 'let is function-scoped', 'They are identical', 'B', 'Because var is function-scoped, a single binding is shared, unlike let which creates a new binding per iteration.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can var behave unexpectedly in loops compared with let?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a falsy value evaluate to in a boolean context?', 'true', 'undefined only', 'false', 'a number', 'C', 'Falsy values like 0, empty string, null, and undefined coerce to false in boolean contexts.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a falsy value evaluate to in a boolean context?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the result of adding a number and a string, like 1 + "2"?', 'The number 3', 'An error', 'undefined', 'The string "12"', 'D', 'The + operator with a string coerces the number to a string and concatenates, giving "12".', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the result of adding a number and a string, like 1 + "2"?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an arrow function not have its own binding of?', 'this', 'parameters', 'a body', 'a return', 'A', 'Arrow functions inherit this from their enclosing scope rather than defining their own.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an arrow function not have its own binding of?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the purpose of JSON in JavaScript applications?', 'A styling language', 'A text format for exchanging structured data', 'A routing protocol', 'A database engine', 'B', 'JSON is a lightweight text format for serializing and exchanging structured data.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the purpose of JSON in JavaScript applications?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does Array.map return?', 'The original array mutated', 'A single number', 'A new array of transformed elements', 'undefined', 'C', 'map produces a new array by applying a function to each element, leaving the original unchanged.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does Array.map return?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the difference between null and undefined?', 'They are identical', 'null is unassigned', 'undefined is a number', 'undefined is unassigned; null is an intentional empty value', 'D', 'undefined marks a variable with no assigned value, while null is an explicit absence of value.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the difference between null and undefined?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the spread operator (...) do with an array?', 'Expands its elements into another array or call', 'Removes elements', 'Sorts the array', 'Reverses the array', 'A', 'Spread expands an iterable''s elements, useful for copying or combining arrays and passing arguments.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the spread operator (...) do with an array?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why are template literals useful?', 'They sort text', 'They allow embedded expressions and multiline strings', 'They encrypt strings', 'They route requests', 'B', 'Template literals use backticks to interpolate expressions and span multiple lines cleanly.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why are template literals useful?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the let keyword provide over var?', 'Global scoping', 'No scoping', 'Block scoping', 'Function scoping only', 'C', 'let is block-scoped, confining the variable to the block in which it is declared.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the let keyword provide over var?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a higher-order function?', 'A function with no arguments', 'A global variable', 'A loop', 'A function that takes or returns a function', 'D', 'Higher-order functions operate on other functions, accepting them as arguments or returning them.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a higher-order function?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does Array.filter return?', 'A new array of elements passing a test', 'The removed elements', 'A boolean', 'The array length', 'A', 'filter returns a new array containing only the elements for which the predicate is true.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does Array.filter return?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does strict mode help with in JavaScript?', 'Faster rendering', 'Catching common mistakes and unsafe actions', 'More global variables', 'Removing functions', 'B', 'Strict mode turns some silent errors into thrown errors and disallows error-prone syntax.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does strict mode help with in JavaScript?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the result of comparing NaN === NaN?', 'true', 'NaN', 'false', 'undefined', 'C', 'NaN is not equal to anything, including itself, so the comparison is false.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the result of comparing NaN === NaN?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is destructuring assignment convenient?', 'It deletes properties', 'It sorts arrays', 'It encrypts data', 'It extracts values from arrays or objects into variables', 'D', 'Destructuring unpacks array elements or object properties directly into named variables.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is destructuring assignment convenient?');

  -- ---- Web Development / DOM Manipulation and Events (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Web Development'
    and t.topic_name = 'DOM Manipulation and Events';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Web Development', 'DOM Manipulation and Events';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the DOM?', 'A tree representation of the page the browser builds', 'A styling language', 'A database', 'A network protocol', 'A', 'The Document Object Model is a tree of nodes representing the page that scripts can read and modify.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the DOM?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does document.querySelector return?', 'All matching elements', 'The first element matching a CSS selector', 'A string of HTML', 'A boolean', 'B', 'querySelector returns the first element that matches the given CSS selector, or null if none.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does document.querySelector return?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does addEventListener do?', 'Removes an element', 'Styles an element', 'Registers a handler for an event on an element', 'Fetches data', 'C', 'addEventListener attaches a callback that runs when the specified event fires on the element.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does addEventListener do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is event bubbling?', 'An event going down to children', 'An event canceling itself', 'A styling effect', 'An event propagating from the target up through ancestors', 'D', 'In bubbling, an event fires on the target then propagates upward through its ancestor elements.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is event bubbling?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does event.preventDefault() do?', 'Stops the browser''s default action for the event', 'Removes the element', 'Styles the element', 'Reloads the page', 'A', 'preventDefault cancels the default behavior, such as a form submitting or a link navigating.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does event.preventDefault() do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is event delegation useful?', 'It removes all events', 'One listener on a parent handles events from many children', 'It styles children', 'It slows the page', 'B', 'Delegation attaches a single listener to a container, handling events from current and future children efficiently.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is event delegation useful?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does element.textContent set or get?', 'The element''s styles', 'The element''s attributes', 'The text inside an element', 'The page URL', 'C', 'textContent reads or writes the plain text content of an element and its descendants.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does element.textContent set or get?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does event.stopPropagation() do?', 'Stops the default action', 'Removes the listener', 'Reloads the page', 'Prevents the event from propagating further', 'D', 'stopPropagation halts the event''s travel through the capturing or bubbling phases.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does event.stopPropagation() do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the difference between innerHTML and textContent?', 'innerHTML parses HTML; textContent treats input as plain text', 'They are identical', 'textContent parses HTML', 'innerHTML is plain text', 'A', 'innerHTML interprets markup, while textContent inserts text literally, which is safer against injection.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the difference between innerHTML and textContent?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why can setting innerHTML with untrusted input be risky?', 'It is always safe', 'It can inject and execute malicious markup', 'It only reads text', 'It speeds the page', 'B', 'Inserting untrusted HTML can introduce cross-site scripting, so untrusted data should be treated as text.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why can setting innerHTML with untrusted input be risky?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does document.createElement do?', 'Deletes an element', 'Styles an element', 'Creates a new element node not yet in the document', 'Fetches data', 'C', 'createElement makes a detached element that you can configure and then insert into the DOM.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does document.createElement do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How do you add a created element to the page?', 'Call preventDefault', 'Set its id only', 'Reload the page', 'Append it to an existing node', 'D', 'Inserting an element, for example with appendChild, attaches it to a parent in the document.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How do you add a created element to the page?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What phase comes before bubbling in DOM event flow?', 'The capturing phase', 'The default phase', 'The reload phase', 'The render phase', 'A', 'Events first travel down in the capturing phase, reach the target, then bubble back up.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What phase comes before bubbling in DOM event flow?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the event object passed to a handler contain?', 'The whole document only', 'Details about the event like its target', 'The server response', 'The CSS rules', 'B', 'The event object carries information such as the target element, type, and coordinates.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the event object passed to a handler contain?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does classList.toggle do?', 'Always adds a class', 'Deletes the element', 'Adds a class if absent or removes it if present', 'Reads the text', 'C', 'toggle flips a class on an element, adding or removing it based on its current presence.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does classList.toggle do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why update the DOM in batches rather than many separate changes?', 'To slow rendering', 'To remove styles', 'To avoid events', 'To reduce layout recalculations and improve performance', 'D', 'Grouping DOM updates limits reflows and repaints, improving rendering performance.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why update the DOM in batches rather than many separate changes?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does getElementById return?', 'The element with the matching id, or null', 'All elements', 'A list of classes', 'A string', 'A', 'getElementById fetches the single element whose id matches, or null if none exists.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does getElementById return?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a DOM node''s parent in the tree?', 'A sibling element', 'The element that directly contains it', 'The document styles', 'The server', 'B', 'A node''s parent is the element one level up that directly contains it.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a DOM node''s parent in the tree?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does removing an event listener require?', 'Only the event name', 'Reloading the page', 'A reference to the same function used to add it', 'Deleting the element', 'C', 'removeEventListener needs the identical function reference originally registered to detach it.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does removing an event listener require?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why might you debounce a scroll or input event handler?', 'To run it more often', 'To remove the event', 'To style the page', 'To limit how often expensive handling runs', 'D', 'Debouncing coalesces rapid events so the handler runs after activity settles, avoiding excessive work.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why might you debounce a scroll or input event handler?');

  -- ---- Web Development / Asynchronous JavaScript (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Web Development'
    and t.topic_name = 'Asynchronous JavaScript';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Web Development', 'Asynchronous JavaScript';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a Promise in JavaScript?', 'An object representing a future value or failure', 'A synchronous loop', 'A CSS rule', 'A DOM node', 'A', 'A Promise represents the eventual result of an asynchronous operation, resolving or rejecting later.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a Promise in JavaScript?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What are the possible states of a Promise?', 'Open or closed', 'Pending, fulfilled, or rejected', 'True or false', 'Fast or slow', 'B', 'A Promise starts pending and settles to either fulfilled or rejected.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What are the possible states of a Promise?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does async/await provide over raw promises?', 'Removing promises entirely', 'Blocking the whole program', 'Writing asynchronous code in a synchronous style', 'Styling output', 'C', 'async/await lets you write promise-based code that reads sequentially, improving clarity.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does async/await provide over raw promises?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the await keyword do?', 'Blocks all threads', 'Cancels a promise', 'Styles a page', 'Pauses an async function until a promise settles', 'D', 'await suspends the async function until the awaited promise resolves, then yields its value.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the await keyword do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is JavaScript described as single-threaded with an event loop?', 'It runs one call stack and queues async callbacks', 'It uses many threads directly', 'It cannot do async work', 'It blocks on every call', 'A', 'JavaScript executes on one thread, using the event loop to run queued callbacks when the stack is clear.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is JavaScript described as single-threaded with an event loop?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What problem does callback nesting (callback hell) cause?', 'Faster execution', 'Deeply nested, hard-to-read asynchronous code', 'Fewer errors', 'No async support', 'B', 'Chaining many callbacks produces deeply nested, hard-to-maintain code that promises help flatten.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What problem does callback nesting (callback hell) cause?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does Promise.then register?', 'A synchronous loop', 'A DOM event', 'A handler to run when the promise fulfills', 'A CSS rule', 'C', 'then schedules a callback to receive the fulfilled value once the promise resolves.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does Promise.then register?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'How are errors handled in an async/await function?', 'They cannot be caught', 'Only with CSS', 'By reloading', 'With try/catch around awaited calls', 'D', 'Wrapping awaited calls in try/catch captures rejected promises as thrown errors.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'How are errors handled in an async/await function?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does fetch return?', 'A promise resolving to a Response object', 'The response body directly', 'A DOM node', 'A number', 'A', 'fetch returns a promise that resolves to a Response, from which the body is read asynchronously.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does fetch return?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why does a long synchronous loop block the UI in the browser?', 'It runs on another thread', 'It occupies the single thread, delaying event handling', 'It speeds rendering', 'It frees the stack', 'B', 'Because the main thread is busy, the event loop cannot process UI events until the loop finishes.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why does a long synchronous loop block the UI in the browser?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does Promise.all do?', 'Waits for the first to settle', 'Rejects immediately', 'Waits for all promises and resolves with their results', 'Runs them sequentially', 'C', 'Promise.all resolves when every input promise fulfills, or rejects if any one rejects.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does Promise.all do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a microtask in the event loop?', 'A long computation', 'A CSS animation', 'A DOM node', 'A promise callback run after the current task', 'D', 'Microtasks, like resolved promise callbacks, run after the current task before the next macrotask.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a microtask in the event loop?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does rejecting a promise represent?', 'An asynchronous operation that failed', 'A successful result', 'A pending state', 'A styling change', 'A', 'Rejection signals that the asynchronous operation failed, delivering an error reason.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does rejecting a promise represent?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does chaining .then calls allow?', 'Removing promises', 'Sequencing asynchronous steps', 'Blocking the thread', 'Styling elements', 'B', 'Returning values or promises from then lets you chain dependent asynchronous steps.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does chaining .then calls allow?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why return a promise from inside a then callback?', 'To cancel the chain', 'To block the thread', 'To wait for it before the next then runs', 'To style output', 'C', 'Returning a promise defers the following then until that promise settles, sequencing async work.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why return a promise from inside a then callback?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does setTimeout schedule?', 'An immediate synchronous call', 'A CSS transition', 'A DOM removal', 'A callback to run after a delay', 'D', 'setTimeout queues a callback to run once after at least the specified delay.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does setTimeout schedule?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does Promise.race resolve or reject with?', 'The outcome of the first settled promise', 'All results combined', 'Only rejections', 'Nothing', 'A', 'Promise.race settles as soon as the first input promise settles, with its value or error.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does Promise.race resolve or reject with?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why prefer await over deeply chained then calls in some code?', 'It blocks the thread', 'It can read more clearly and linearly', 'It removes error handling', 'It avoids promises', 'B', 'await can express sequential async logic more readably than long then chains.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why prefer await over deeply chained then calls in some code?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What happens to an unhandled promise rejection?', 'It is always ignored safely', 'It resolves the promise', 'It can trigger a warning or error', 'It reloads the page', 'C', 'Unhandled rejections surface as warnings or errors, signaling a missing catch handler.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What happens to an unhandled promise rejection?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the event loop do when the call stack is empty?', 'It stops the program', 'It clears all variables', 'It reloads the page', 'It takes the next queued callback to run', 'D', 'When the stack clears, the event loop dequeues the next ready callback to execute.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the event loop do when the call stack is empty?');

  -- ---- Web Development / Responsive Design (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Web Development'
    and t.topic_name = 'Responsive Design';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Web Development', 'Responsive Design';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the goal of responsive web design?', 'Adapting layout to different screen sizes', 'Running server code', 'Encrypting data', 'Routing requests', 'A', 'Responsive design makes a single site adjust its layout to look good across device sizes.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the goal of responsive web design?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What CSS feature applies styles based on viewport width?', 'Event listeners', 'Media queries', 'Promises', 'Semantic tags', 'B', 'Media queries let CSS respond to conditions like viewport width to adjust layout.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What CSS feature applies styles based on viewport width?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a mobile-first approach mean?', 'Ignoring mobile devices', 'Only desktop styles', 'Designing base styles for small screens first', 'Server-first rendering', 'C', 'Mobile-first writes base styles for small screens and layers enhancements for larger ones.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a mobile-first approach mean?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a fluid layout?', 'A fixed-pixel layout', 'A print layout', 'A server layout', 'One using relative units that scale with the viewport', 'D', 'A fluid layout uses relative widths so content scales smoothly with the available space.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a fluid layout?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is the viewport meta tag important for mobile pages?', 'It sets how the page scales to the device width', 'It styles the body', 'It runs scripts', 'It fetches data', 'A', 'Without a proper viewport meta tag, mobile browsers render pages zoomed out at a desktop width.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is the viewport meta tag important for mobile pages?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a breakpoint define in responsive design?', 'A JavaScript error', 'A width where the layout changes', 'A server route', 'A font family', 'B', 'A breakpoint is a viewport size at which media queries adjust the layout.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a breakpoint define in responsive design?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why use relative units like rem or percentages for responsiveness?', 'They are always larger', 'They disable media queries', 'They scale with context rather than being fixed', 'They are server-side', 'C', 'Relative units adapt to context, helping layouts and text scale across screen sizes.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why use relative units like rem or percentages for responsiveness?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a flexible image technique like max-width: 100% achieve?', 'Images grow beyond the screen', 'Images are removed', 'Images become text', 'Images shrink to fit their container', 'D', 'Setting max-width to 100% lets images scale down to their container without overflowing.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a flexible image technique like max-width: 100% achieve?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the benefit of CSS Grid for responsive layouts?', 'It can rearrange rows and columns at breakpoints', 'It only works on one screen size', 'It disables media queries', 'It runs on the server', 'A', 'Grid can redefine its track structure across breakpoints, adapting complex layouts responsively.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the benefit of CSS Grid for responsive layouts?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What problem does a fixed-width layout cause on small screens?', 'Perfect fit everywhere', 'Horizontal scrolling or clipped content', 'Faster loading', 'Better accessibility', 'B', 'A fixed width wider than the screen forces horizontal scrolling or cuts off content on small devices.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What problem does a fixed-width layout cause on small screens?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the term adaptive design often emphasize compared with responsive?', 'A single fluid layout', 'No layout changes', 'Distinct layouts for specific device sizes', 'Server rendering only', 'C', 'Adaptive design uses several fixed layouts chosen per device class, versus one continuously fluid layout.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the term adaptive design often emphasize compared with responsive?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What CSS unit is relative to the root font size?', 'px', 'cm', 'pt', 'rem', 'D', 'The rem unit is relative to the root element''s font size, aiding scalable typography.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What CSS unit is relative to the root font size?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why test responsive designs on real devices or emulators?', 'Rendering and interaction vary across devices', 'Testing is unnecessary', 'It changes the server', 'It removes CSS', 'A', 'Different devices and browsers render and handle input differently, so testing catches real issues.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why test responsive designs on real devices or emulators?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does min-width in a media query target?', 'Viewports narrower than that', 'Viewports at least that wide', 'Only print', 'The server width', 'B', 'A min-width media query applies when the viewport is at least the specified width, common in mobile-first CSS.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does min-width in a media query target?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a flexible grid system?', 'Fixed pixel columns only', 'A single column always', 'Columns defined in relative proportions', 'A server template', 'C', 'A flexible grid sizes columns proportionally so content reflows across screen widths.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a flexible grid system?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why avoid designing only for one specific screen resolution?', 'Resolutions never vary', 'It speeds the server', 'It is required by HTML', 'Users have many device sizes and orientations', 'D', 'Targeting one resolution breaks on the wide range of devices and orientations users have.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why avoid designing only for one specific screen resolution?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does orientation in a media query detect?', 'Whether the viewport is portrait or landscape', 'The font size', 'The server region', 'The color depth only', 'A', 'An orientation media query distinguishes portrait from landscape layouts.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does orientation in a media query detect?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the effect of using viewport-relative units like vw?', 'Sizes stay fixed', 'Sizes scale with the viewport width', 'Sizes depend on the server', 'Sizes are in centimeters', 'B', 'The vw unit is a percentage of the viewport width, so values scale as the viewport changes.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the effect of using viewport-relative units like vw?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is content prioritization important on small screens?', 'Small screens show everything equally', 'It changes the server', 'Limited space requires showing the most important content first', 'It removes styling', 'C', 'With little room, responsive designs surface the most important content and defer the rest.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is content prioritization important on small screens?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a responsive navigation pattern like a hamburger menu solve?', 'Adding more desktop links', 'Server routing', 'Image compression', 'Fitting navigation into limited mobile space', 'D', 'A collapsible menu conserves screen space on small devices while keeping navigation accessible.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a responsive navigation pattern like a hamburger menu solve?');

  -- ---- Web Development / HTTP and REST APIs (20 questions) ----
  select t.id into v_topic_id
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.subject_name = 'Web Development'
    and t.topic_name = 'HTTP and REST APIs';
  if v_topic_id is null then
    raise exception 'topic not found: % / %', 'Web Development', 'HTTP and REST APIs';
  end if;
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a RESTful API typically use to identify resources?', 'URLs (endpoints)', 'MAC addresses', 'CSS selectors', 'DOM nodes', 'A', 'REST exposes resources at URLs, which clients act on using HTTP methods.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a RESTful API typically use to identify resources?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which HTTP method is used to retrieve a resource without modifying it?', 'POST', 'GET', 'DELETE', 'PUT', 'B', 'GET requests a resource and should not change server state (it is safe and idempotent).', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which HTTP method is used to retrieve a resource without modifying it?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Which HTTP method typically creates a new resource?', 'GET', 'HEAD', 'POST', 'OPTIONS', 'C', 'POST submits data to create a new resource under a collection.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Which HTTP method typically creates a new resource?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an HTTP status code in the 200 range indicate?', 'A client error', 'A server error', 'A redirect', 'Success', 'D', '2xx codes indicate the request succeeded, such as 200 OK or 201 Created.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an HTTP status code in the 200 range indicate?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a 404 status code mean?', 'The resource was not found', 'The request succeeded', 'The server failed', 'Authentication is required', 'A', 'A 404 indicates the server could not find the requested resource.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a 404 status code mean?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What makes an HTTP method idempotent?', 'It always creates new resources', 'Repeating it yields the same server state', 'It changes state each time', 'It cannot be repeated', 'B', 'An idempotent method like PUT or DELETE produces the same effect whether called once or many times.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What makes an HTTP method idempotent?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why is PUT often considered idempotent but POST is not?', 'POST replaces resources', 'PUT creates duplicates', 'PUT replaces a resource; repeated POSTs can create duplicates', 'They are identical', 'C', 'PUT sets a resource to a given state repeatably, while repeated POSTs may create multiple resources.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why is PUT often considered idempotent but POST is not?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a 500-range status code indicate?', 'A successful request', 'A client error', 'A redirect', 'A server-side error', 'D', '5xx codes signal that the server failed to fulfill a valid request.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a 500-range status code indicate?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is a common data format for REST API payloads?', 'JSON', 'CSS', 'HTML only', 'Binary images only', 'A', 'REST APIs commonly exchange data as JSON, a lightweight structured text format.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is a common data format for REST API payloads?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does statelessness mean for a REST API?', 'The server stores client sessions', 'Each request carries all needed information', 'Requests depend on prior ones', 'The client stores nothing', 'B', 'REST is stateless, so each request is self-contained and the server keeps no client session between calls.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does statelessness mean for a REST API?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does the DELETE method do?', 'Creates a resource', 'Reads a resource', 'Removes the identified resource', 'Updates headers only', 'C', 'DELETE requests removal of the resource at the given URL.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does the DELETE method do?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is the role of an HTTP request header?', 'Holding the response body', 'Styling the page', 'Routing at the link layer', 'Carrying metadata like content type and auth', 'D', 'Request headers convey metadata such as content type, accepted formats, and credentials.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is the role of an HTTP request header?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a 401 status code indicate?', 'Authentication is required or failed', 'The resource moved', 'The server crashed', 'Success', 'A', 'A 401 means the request lacks valid authentication for the resource.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a 401 status code indicate?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does content negotiation via the Accept header allow?', 'The server to pick a route', 'The client to request a preferred response format', 'The client to style a page', 'The server to delete data', 'B', 'The Accept header tells the server which representation formats the client prefers.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does content negotiation via the Accept header allow?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why use path parameters versus query parameters in a REST URL?', 'They are identical', 'Query identifies the resource', 'Path identifies a resource; query filters or options it', 'Path only filters', 'C', 'Path segments typically identify a specific resource, while query strings refine or filter the result.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why use path parameters versus query parameters in a REST URL?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a 201 Created status code signal?', 'The resource was deleted', 'A redirect occurred', 'A server error', 'A new resource was successfully created', 'D', 'A 201 indicates the request succeeded and resulted in a new resource.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a 201 Created status code signal?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What is CORS concerned with?', 'Browser rules for cross-origin requests', 'Server-side routing', 'CSS layout', 'Database indexing', 'A', 'CORS governs whether a browser permits a page to make requests to a different origin.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What is CORS concerned with?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does an authorization token in a request header enable?', 'Styling the response', 'Proving the client is permitted to access a resource', 'Routing packets', 'Compressing images', 'B', 'A bearer token in the Authorization header authenticates the client to protected endpoints.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does an authorization token in a request header enable?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'Why should GET requests avoid side effects?', 'They always modify data', 'They cannot be cached', 'They are expected to be safe and cacheable', 'They require a body', 'C', 'GET is defined as safe, so clients and caches may repeat it without changing server state.', 3
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'Why should GET requests avoid side effects?');
  insert into public.diagnostic_questions
    (topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty)
  select v_topic_id, 'What does a well-designed REST endpoint return on a successful resource fetch?', 'A 500 error', 'An empty body with 404', 'A redirect only', 'The resource representation with a 200 status', 'D', 'A successful fetch returns the resource data, typically as JSON, with a 200 OK status.', 2
  where not exists (select 1 from public.diagnostic_questions q
    where q.topic_id = v_topic_id and q.question = 'What does a well-designed REST endpoint return on a successful resource fetch?');
end $$;
