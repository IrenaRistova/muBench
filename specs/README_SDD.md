# SDD Toolkit - µBench Research Project

**Spec-Driven Development toolkit for Cursor IDE**

Transform research ideas into structured, production-ready implementations.

---

## 🎯 What is SDD for Our Research Project?

Spec-Driven Development helps us create detailed specifications **before** writing code. This ensures:

- 🎯 **Clear requirements** from research goals before implementation

- 🏗️ **Well-planned technical decisions** based on existing architecture

- 📋 **Structured development tasks** aligned with our codebase patterns

- 🤝 **Better team alignment** through shared understanding

- 🚀 **Faster delivery** with fewer iterations

---

## 🚀 Quick Start

### Your Typical Workflow

1. **Get a research task** - Benchmarking experiment, system configuration, feature development

2. **Choose your approach** - Simple (80%) or Complex (20%)

3. **Follow the workflow** for your chosen approach

4. **Start coding** with clear requirements and implementation approach

---

## 📋 Two Approaches: Simple vs Complex

### 🟢 Approach 1: Simple Tasks (80% of features)

**Use this for most research tasks**

**When to use:**

- ✅ Single feature with clear requirements

- ✅ Well-defined scope (1-2 weeks)

- ✅ Fits existing architecture patterns

- ✅ Have clear research goals and requirements

**Example tasks:**

- "Add SSH tunnel script for gateway access"

- "Create new topology configuration"

- "Add monitoring dashboard configuration"

- "Create new workmodel for specific topology"

**Workflow:**

```bash
# Step 1: Create brief (30 min)
/brief gateway-tunnel-script Create SSH tunnel script for nginx gateway access from host machine

# Step 2: Review and start coding
→ Review the brief
→ Start coding following the implementation approach
→ Reference the brief as you code

# Step 3: Update as needed (optional, 2-5 min)
/evolve gateway-tunnel-script Discovered need for cleanup of existing tunnels before starting new ones

# Step 4: Complete
→ Brief serves as documentation
```

**What you get:**

- Single file: `specs/active/gateway-tunnel-script/feature-brief.md`

- Requirements extracted from research goals

- Implementation approach based on codebase patterns

- 2-3 immediate next actions

- Ready to code in ~30 minutes

---

### 🔴 Approach 2: Complex Tasks (20% of features)

**Use this for architecturally complex features**

**When to use:**

- ⚠️ Multiple components involved (muBench + Experiment Runner + Locust)

- ⚠️ Affects multiple systems (Kubernetes, monitoring, benchmarking)

- ⚠️ Architectural changes required

- ⚠️ Complex research requirements

- ⚠️ Multiple integration points

**Example tasks:**

- "Integrate Experiment Runner with muBench deployments"

- "Set up automated benchmarking pipeline"

- "Create energy measurement integration"

- "Build dataset collection system"

**Workflow:**

```bash
# Step 1: Research existing patterns (1-2 hrs)
/research experiment-runner-integration Integrate Experiment Runner with muBench for automated benchmarking

# Step 2: Create detailed requirements (1-2 hrs)
/specify experiment-runner-integration Automated experiment orchestration with muBench deployments

# Step 3: Create technical plan (1-2 hrs)
/plan experiment-runner-integration

# Step 4: Break down into tasks (1-2 hrs)
/tasks experiment-runner-integration

# Step 5: Implement
→ Follow tasks.md systematically
→ Update progress as you go
```

**What you get:**

- Multiple files: `research.md`, `spec.md`, `plan.md`, `tasks.md`

- Comprehensive documentation at each level

- Detailed task breakdown with dependencies

- Architecture decisions documented

- Ready for implementation following tasks

**Total time:** ~4-6 hours planning → Start implementation

---

## 📚 Command Reference

### 🚀 `/brief` - Create Feature Brief (Simple Tasks)

**Use for:** 80% of research tasks

```bash
/brief [task-id] [description]
```

**Example:**

```bash
/brief monitoring-tunnel-script Create SSH tunnel script for monitoring services (Prometheus, Grafana, Jaeger, Kiali)
```

**Creates:** `specs/active/monitoring-tunnel-script/feature-brief.md`

- Requirements from research goals

- Research on existing patterns

- Implementation approach

- Next actions (2-3 tasks)

**Time:** ~30 minutes planning → start coding

---

### 🔄 `/evolve` - Update During Development

**Use when:** You discover things while coding

```bash
/evolve [task-id] [what-you-discovered]
```

**When to use:**

1. **New requirements discovered** - "Need to support cleanup of existing tunnels"

2. **Technical discoveries** - "kubectl port-forward requires namespace specification"

3. **Scope changes** - "Added support for gateway tunnel in addition to monitoring"

4. **Implementation decisions** - "Changed from single script to separate server/host scripts"

5. **Dependencies found** - "Need to integrate with existing setup.sh script"

**Example:**

```bash
/evolve monitoring-tunnel-script Discovered need for separate local script for host machine SSH tunnel setup
```

**What it does:**

- Updates `feature-brief.md` with new information

- Adds changelog entry explaining the change (date, reason, impact)

- Shows before/after comparison of modified sections

- Maintains alignment between spec and code

**Time:** 2-5 minutes during development

**Pro Tip:** Use `/evolve` whenever you think "this should have been in the brief" or "the brief is now outdated."

---

### 🏗️ `/research` - Deep Pattern Investigation (Complex Tasks)

**Use for:** Complex tasks requiring pattern research

```bash
/research [task-id] [research-topic]
```

**Example:**

```bash
/research experiment-runner-integration Integrate Experiment Runner with muBench for automated benchmarking experiments
```

**Creates:** `specs/active/experiment-runner-integration/research.md`

- Existing muBench deployment patterns

- Experiment Runner integration patterns

- Locust workload generation patterns

- Monitoring and metric collection patterns

**Use when:**

- Task is architecturally complex

- Need to understand existing patterns first

- Multiple systems involved (muBench, Experiment Runner, Locust, Prometheus)

---

### 🎯 `/specify` - Detailed Requirements (Complex Tasks)

**Use for:** Complex tasks with multiple requirements

```bash
/specify [task-id] [description]
```

**Example:**

```bash
/specify energy-measurement-integration Integrate energy measurement tools with muBench benchmarking pipeline
```

**Creates:** `specs/active/energy-measurement-integration/spec.md`

- All research requirements broken down

- System requirements with acceptance criteria

- Edge cases and error scenarios

- Success metrics

**Use when:**

- Task has multiple requirements

- Multiple systems involved

- Complex integration requirements

---

### 🏗️ `/plan` - Technical Implementation Plan (Complex Tasks)

**Use after:** `/specify` for complex features

```bash
/plan [task-id]
```

**Prerequisites:** Must have `spec.md` file

**Example:**

```bash
/plan energy-measurement-integration
```

**Creates:** `specs/active/energy-measurement-integration/plan.md`

- Architecture approach (muBench + Experiment Runner + energy tools)

- Technology stack decisions

- Integration points and data flow

- Security and performance considerations

- Integration with existing systems

**Use when:**

- Feature affects multiple systems

- Architectural decisions needed

- Complex integration requirements

---

### 📋 `/tasks` - Break Down into Tasks (Complex Tasks)

**Use after:** `/plan` for complex features

```bash
/tasks [task-id]
```

**Prerequisites:** Must have `plan.md` file

**Example:**

```bash
/tasks energy-measurement-integration
```

**Creates:** `specs/active/energy-measurement-integration/tasks.md`

- Prioritized task breakdown

- Dependencies between tasks

- Effort estimates

- Definition of done for each task

**Use when:**

- Feature is complex and needs task breakdown

- Multiple components to integrate

- Need to track progress across multiple tasks

---

## 🎨 PLAN Mode: See Before Create

All SDD commands use **PLAN mode** - you see what will be created before it happens.

### How It Works

1. **Analysis** - AI reads requirements, searches codebase, understands architecture

2. **Plan** - AI presents what will be created/modified (files, structure, approach)

3. **Review** - You review and approve (or request changes)

4. **Execute** - AI creates files as planned

**Benefits:**

- 👁️ See what will be created before files are made

- ✅ Approve or modify approach before execution

- 🧠 Understand AI's reasoning based on codebase

- 🛡️ No surprise file changes

---

## 🔧 Working with Research Tasks

### Best Practices

1. **Include Research Context**

   - Mention research phase (Phase 3: Benchmarking, Phase 4: Usage Showcase, etc.)

   - Include key requirements from research goals

   - Reference related tools (muBench, Experiment Runner, Locust)

2. **Use Semantic Task IDs**

   - Use descriptive names: `gateway-tunnel-script`, `experiment-runner-integration`

   - Matches research task for easy reference

   - Links specs to research phases

3. **Reference Existing Patterns**

   - Mention existing scripts: "Similar to monitoring-tunnel.sh"

   - Reference configuration files: "Follow pattern from K8sParameters.json"

   - AI will note these in the brief

4. **Extract Requirements**

   - List key requirements from research goals

   - AI will structure them as requirements

   - Easy to verify completeness

---

## 📁 Project Structure

```
muBench/
├── specs/
│   ├── 00-overview.md          # Project overview (muBench architecture, research goals)
│   ├── README_SDD.md            # SDD toolkit guide (this file)
│   ├── index.md                 # Feature status dashboard
│   ├── active/                  # Features in development
│   │   ├── gateway-tunnel-script/  # Simple task (brief only)
│   │   │   └── feature-brief.md
│   │   ├── experiment-runner-integration/  # Complex task (full SDD)
│   │   │   ├── research.md     # Pattern research
│   │   │   ├── spec.md          # Detailed requirements
│   │   │   ├── plan.md          # Technical plan
│   │   │   └── tasks.md         # Task breakdown
│   │   └── ...
│   ├── completed/               # Delivered features
│   └── backlog/                 # Future features
├── .sdd/                        # SDD configuration
│   ├── config.json              # Settings
│   ├── guidelines.md            # SDD guidelines
│   └── templates/               # Document templates
└── .cursor/commands/            # SDD commands
```

---

## 💡 Tips for Research Project

### 1. Start Simple, Scale When Needed

- **Most tasks:** Use `/brief` → start coding

- **Complex tasks:** Use `/research` → `/specify` → `/plan` → `/tasks`

### 2. Keep Specs Updated During Development

- Use `/evolve` when you discover things

- Keep specs aligned with implementation

- Update when requirements change

### 3. Reference Existing Patterns

- AI searches codebase automatically

- Leverages existing patterns (scripts, configs, deployment patterns)

- Maintains consistency with muBench architecture

### 4. Use Semantic Task IDs

- Use descriptive names: `gateway-tunnel-script`, `energy-measurement-integration`

- Easy to link specs to research tasks

- Clear organization

### 5. Reference Research Phases

- Mention which research phase you're working on

- Reference research goals from overview

- Link to related tools (muBench, Experiment Runner, Locust)

---

## 🔗 Links

- [Project Overview](00-overview.md) - µBench architecture, research goals, and project structure

- [SDD Guidelines](../.sdd/guidelines.md) - Detailed SDD methodology

- [SDD Configuration](../.sdd/config.json) - Toolkit settings

- [µBench Manual](../Docs/Manual.md) - Complete µBench documentation

- [µBench Repository](https://github.com/mSvcBench/muBench) - Official µBench repository

---

## 📝 Notes

- **Task IDs:** Use semantic names (e.g., `gateway-tunnel-script`, `experiment-runner-integration`)

- **Research Phases:** Reference Phase 3 (Benchmarking), Phase 4 (Usage Showcase), Phase 5 (Reporting)

- **Tools:** Reference muBench, Experiment Runner, Locust, Prometheus, Grafana

- **Architecture:** Reference Kubernetes, minikube, Docker, SSH tunnels

- **Configuration:** Reference existing configs (K8sParameters.json, RunnerParameters.json, etc.)

---

## 🎯 Research Project Context

### Current Research Phases

- **Phase 3: Benchmarking** - Run Experiment Runner, collect CPU/power metrics, logging
  - ✅ Locust workload generator integrated and tested
  - 🔄 Experiment Runner integration (pending)
- **Phase 4: Usage Showcase** - Descriptive statistics, visualizations, plots
- **Phase 5: Reporting** - ACM format report, GitHub dataset repository

### Key Tools

- **µBench** - Microservice application factory
- **Experiment Runner** - Experiment orchestration framework (pending integration)
- **Locust** - Workload generation ✅ **INTEGRATED** (v2.42.2, tested and ready)
- **Prometheus/Grafana** - Monitoring and visualization
- **Kubernetes/minikube** - Container orchestration

### Research Goals

- Evaluate performance and energy efficiency of different topologies
- Study system size impact (5, 10, 20 services)
- Build reusable benchmarking dataset
- Support future AI-based orchestration research

---

**Ready to transform your research tasks into structured implementations!**

Start with `/brief` for your next research task.

