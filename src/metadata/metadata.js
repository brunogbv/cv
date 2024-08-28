module.exports = {
  name: 'Bruno Guilhermo de Barros Valério',
  title: 'Engineering Manager',
  facts: [
    {
      icon: '<i class="fa-solid fa-location-dot fact-icon"></i>',
      value: '<a href="https://www.google.com/maps/place/Berlin/@52.5200066,13.404954">Berlin, Germany</a>'
    },
    {
      icon: '<i class="fa-solid fa-envelope fact-icon"></i>',
      value: '<a href="mailto:bruno@valerio.dev">bruno@valerio.dev</a>'
    },
    {
      icon: '<i class="fa-brands fa-linkedin fact-icon"></i>',
      value: '<a href="https://www.linkedin.com/in/brunogbv">brunogbv</a>'
    },
    {
      icon: '<i class="fa-brands fa-github fact-icon"></i>',
      value: '<a href="https://github.com/brunogbv/">brunogbv</a>'
    }
  ],
  about_me: `
  With a background in Control and Automation Engineering, I found my passion when I transitioned to Software Engineering. Initially working on embedded systems for Robotics applications, I fell in love with Distributed Systems and Reactive Architecture and I decided to change my specialization.

  With over 7 years of experience in Distributed Systems, I'm committed to building scalable, highly available and fault-tolerant services. My goal is to reduce ambiguity and bridge the gap between the engineering and business world.
  `,
  skills: [
    ['Distributed Systems', 100],
    ['Teamwork', 100],
    ['Communication', 90],
    ['English', 100],
    ['Portuguese', 100],
    ['Spanish', 80],
    ['German', 30],
    ['Stakeholder Management', 80],
    ['Leadership', 80],
    ['People Management', 80],
    ['Functional Programming', 70],
    ['Object-Oriented Programming', 100],
    ['Reactive Programming', 100],
    ['Event Driven Architecture', 100],
    ['CQRS', 90],
    ['Microservices', 100],
    ['Cloud Native Apps', 100],
    ['AWS', 80],
    ['GCP', 50],
    ['REST API', 100],
    ['gRPC', 100],
    ['GraphQL', 60],
    ['Akka Stack', 100],
    ['Split-Brain Resolver', 80],
    ['CAP Theorem', 100],
    ['Apache Cassandra', 70],
    ['Apache Flink', 100],
    ['Apache Kafka', 100],
    ['SQL', 100],
    ['Redis', 100],
    ['Elasticsearch', 70],
    ['Scala', 100],
    ['Kotlin', 80],
    ['Java', 80],
    ['Go', 70],
    ['C++', 80]
  ],
  positions: [
    {
      title: 'Engineering Manager at Flink, Berlin',
      period: 'November 2023 – Present',
      skills: ['Stakeholder Management', 'Product & Engineering', 'Go', 'GCP', 'Kubernetes', 'PostgreSQL', 'Redis', 'Terraform', 'Helm', 'ArgoCD', 'Docker', 'Datadog', 'PagerDuty', 'incident.io', 'Microservices', 'REST API', 'Object-Oriented Programming'],
      contents: `
Hired based on previous experience at Delivery Hero to manage the dispatching team, responsible for core operations at Flink.

Key goals included:

  - Hiring and onboarding new team members

  - Optimizing staff utilization (riders and pickers) to achieve unit economic profitability

  - Leading the design of a new architecture to transition from a monolith service to microservices, scaling the organization and establishing the dispatching team as a domain.

We have successfully achieved the first two goals, reaching record high rider utilisation rate (UTR). This has allowed our company to focus on growth and expansion.
`
    },
    {
      title: 'Engineering Manager at Delivery Hero, Berlin',
      period: 'May 2022 – November 2023',
      skills: ['Stakeholder Management', 'Product & Engineering', 'Scala', 'Akka', 'Akka Streams', 'Akka Cluster', 'Akka HTTP', 'Akka Persistence', 'AWS', 'Kubernetes', 'PostgreSQL', 'Redis', 'Terraform', 'Helm', 'Spinnaker', 'Docker', 'Prometheus', 'Grafana', 'Datadog', 'OpsGenie', 'Microservices', 'REST API', 'Reactive Programming', 'Functional Programming', 'Object-Oriented Programming'],
      contents: `
Transitioned to Engineering Manager role with a focus on hiring and rebuilding the routing-infra team. Took on additional responsibilities to maintain operations during the hiring process and challenged existing practices to address various issues:

  - Monolith service limiting team autonomy, org growth and impacting our domain's deliverables.

  - Difficult-to-source tech stack leading to higher hiring costs without clear benefits

  - Slow cycle times due to monolith service and lack of design patterns

  - Heavy burden of On Call Duty with 24/7 operations across 50+ countries.


Key Achievements:

I addressed all the problems above and looked into extra initiatives that I also deemed important for our team:

  - Successfully hired and onboarded a team of 5 self-driven engineers in under 6 months, avoiding the need for micromanagement.

  - Managed back-to-back on call shifts for almost a year, being solely responsible for a tier 0 service operating 24/7 globally.

  - Transitioned the domain to a new tech stack, replacing Scala and Akka with Kotlin and microframeworks such as Quarkus and Micronaut.

  - Initiated native runtime projects with GraalVM, reducing memory footprint by 50% and boot times from 1 minute to 0.3 seconds.

  - Designed a new architecture, breaking down the monolith into decoupled microservices, restoring team autonomy in the Routing domain.

  - Advocated for Hexagonal Architecture, implementing a common design pattern across the domain, improving cycle times by over 40%.

  - Refactored the event consumption workflow, incorporating backpressure capabilities via Akka Streams to handle mismatched consumer and producer rates.

  - Implemented an On Call Handover process that was focused on creating action items after each rotation to address the problems that happened during the shift. We were able to reduce our noise by 94% which greatly improved DevEx

  - Presented on Scalability and Reliability success at the Delivery Hero Summit, an internal event attended by employees from Delivery Hero and its subsidiaries, including Glovo, Foodpanda, Talabat, Yemeksepeti, and Woowa Brothers.
`
    },
    {
      title: 'Senior Software Engineer at Delivery Hero, Berlin',
      period: 'February 2021 – May 2022',
      skills: ['Scala', 'Akka', 'Akka Streams', 'Akka Cluster', 'Akka HTTP', 'Akka Persistence', 'AWS', 'Kubernetes', 'PostgreSQL', 'Redis', 'Terraform', 'Helm', 'Spinnaker', 'Docker', 'Prometheus', 'Grafana', 'Datadog', 'OpsGenie', 'Microservices', 'REST API', 'Reactive Programming', 'Functional Programming', 'Object-Oriented Programming'],
      contents: `
Contributed to the growth of the Routing team into a domain comprising three teams: routing-infra, routing-optimization, and routing-experimentation. Operated within a highly cross-functional team environment, emphasizing collaboration and communication to manage a single, large-scale production service.

Key Achievements:

  - Took responsibility for On Call Duty, onboarding, and training domain members, supporting all three teams with a single rotation.

  - Improved load testing cycles with a new setup, identifying more issues. Removed Event Sourcing and SQL database with Redis as the main storage, scaling the load factor from 5x to 16x and resolving scalability issues.

  - Reduced running costs of the dispatch service by 46% by selecting optimal storage solutions for each workflow after addressing scalability.

  - Interviewed candidates at up to senior level, conducting both code and system design challenges.
`
    },
    {
      title: 'Software Engineer at Delivery Hero, Berlin',
      period: 'January 2020 – February 2021',
      skills: ['Scala', 'Akka', 'Akka Streams', 'Akka Cluster', 'Akka HTTP', 'Akka Persistence', 'AWS', 'Kubernetes', 'PostgreSQL', 'Redis', 'Terraform', 'Helm', 'Spinnaker', 'Docker', 'Prometheus', 'Grafana', 'Datadog', 'OpsGenie', 'Microservices', 'REST API', 'Reactive Programming', 'Functional Programming', 'Object-Oriented Programming'],
      contents: `
Working on the Logistics department, Routing Team. Maintained and developed the dispatch service operating in 50+ countries, a tier 0 service solving complex Vehicle Routing Problems (VRP). Optimized order-courier connections to reduce delivery times, minimize distance covered, and maximize rider utilization rates. Utilized CQRS and Akka to build horizontally scalable, highly available systems for enhanced customer, rider, and restaurant experiences.

Key Achievements:

  - Identified performance bottlenecks and improved the scalability of the dispatch service, increasing its load factor from 1x to 5x within the first six months.

  - Created a custom load test setup using Gatling, which streamlined testing by mocking external services, thereby improving the efficiency of the testing cycle.

  - Promoted to a Senior position within a year due to exceptional performance and exceeding mid-level engineering expectations.
`
    },
    {
      title: 'Sr. Software Engineer at iU Pay, Rio de Janeiro',
      period: 'April 2019 – December 2019',
      skills: ['Scala', 'Akka', 'Akka Streams', 'Akka Cluster', 'Akka HTTP', 'Akka Persistence', 'CQRS', 'Apache Kafka', 'Docker', 'Microservices', 'REST API', 'Reactive Programming', 'Functional Programming', 'Object-Oriented Programming'],
      contents: `
First engineer to join this startup which was successfully sold to a estabilished fintech in less than 2 years. Small team of 5 engineers, CTO, CEO and COO. Managerless, reporting directly to CTO. Developed a real-time fast payment solution in Scala heavily focused on reactive programming and architecture. Leveraged the full Akka stack, including the recently released Akka Typed, to enhance type safety. Utilized Apache Cassandra as the primary database and Apache Kafka as the streaming platform.
`
    },
    {
      title: 'Software Developer at Stone Pagamentos, Rio de Janeiro',
      period: 'July 2017 - April 2019',
      skills: ['Scala', 'Akka', 'Akka Streams', 'Akka Cluster', 'Akka HTTP', 'Apache Kafka', 'MySQL', 'RabbitMQ', 'InfluxDB', 'Docker', 'Microservices', 'REST API', 'Reactive Programming', 'Functional Programming', 'Object-Oriented Programming', 'Elasticsearch', 'Logstash', 'Kibana', 'Grafana'],
      contents: `
Developed concurrent systems in Scala, focusing on real-time data monitoring and processing. Utilized Functional Programming, Domain-Driven Design (DDD), Command Query Responsibility Segregation (CQRS), and Event Sourcing to build highly available, fault-tolerant, and horizontally scalable systems. Implemented and integrated technologies such as Akka, Akka Cluster, Akka Streams, Apache Kafka, Apache ZooKeeper, Apache Flink, RabbitMQ, InfluxDB, MySQL and MongoDB. Created REST APIs to enable seamless internet-based communication for these systems.
`
    }
  ],
  experience: [
    {
      title: 'Reactive Architecture: Building Scalable Systems, Lightbend Academy',
      period: 'June 2020',
      skills: ['Reactive Programming', 'Distributed Systems', 'Functional Programming', 'Event Driven Architecture', 'CQRS', 'Microservices', 'Cloud Native Apps', 'Akka Stack'],
      contents: `
`
    },
    {
      title: 'Reactive Architecture: CQRS and Event Sourcing, Lightbend Academy',
      period: 'June 2020',
      skills: ['Reactive Programming', 'Distributed Systems', 'Functional Programming', 'Event Driven Architecture', 'CQRS', 'Event Sourcing', 'Microservices', 'Cloud Native Apps', 'Akka Stack'],
      contents: `
`
    },
    {
      title: 'Reactive Architecture: Distributed Messaging Patterns, Lightbend Academy',
      period: 'June 2020',
      skills: ['Reactive Programming', 'Distributed Systems', 'Functional Programming', 'Event Driven Architecture', 'Microservices', 'Cloud Native Apps', 'Akka Stack'],
      contents: `
`
    },
    {
      title: 'Reactive Architecture: Domain Driven Design, Lightbend Academy',
      period: 'April 2020',
      skills: ['Reactive Programming', 'Distributed Systems', 'Functional Programming', 'DDD', 'Microservices', 'Cloud Native Apps', 'Akka Stack'],
      contents: `
`
    },
    {
      title: 'Reactive Architecture: Reactive Microservices, Lightbend Academy',
      period: 'April 2020',
      skills: ['Reactive Programming', 'Distributed Systems', 'Functional Programming', 'Event Sourcing', 'Microservices', 'Cloud Native Apps', 'Akka Stack'],
      contents: `
`
    },
    {
      title: 'Akka Cluster Fundamentals, Lightbend Academy',
      period: 'March 2020',
      skills: ['Reactive Programming', 'Distributed Systems', 'Functional Programming', 'Split Brain Resolver', 'Akka Cluster', 'Microservices', 'Cloud Native Apps', 'Akka Stack', 'Split-Brain Resolver'],
      contents: `
`
    },
    {
      title: 'Akka Streams for Scala Professional, Lightbend Academy',
      period: 'March 2020',
      skills: ['Reactive Programming', 'Reactive Streams', 'Functional Programming', 'Microservices', 'Cloud Native Apps', 'Akka Streams', 'Event Consumption Backpressure (Dynamic Push-Pull)'],
      contents: `
`
    },
    {
      title: 'Reactive Architecture: Introduction to Reactive Systems, Lightbend Academy',
      period: 'March 2020',
      skills: ['Reactive Programming', 'Fault Tolerance', 'Scalability', 'Availability', 'Event Driven Architecture'],
      contents: `
`
    },
    {
      title: 'Data Science and Big Data Analytics: Making Data-Driven Decisions, Massachusetts Institute of Technology',
      period: 'January 2019 – March 2019',
      skills: ['Supervised Learning', 'Unsupervised Learning', 'Clustering', 'Deep Learning', 'Neural Networks', 'Recommendation Systems'],
      contents: `
`
    },
    {
      title: 'English Immersion Course | Bournemouth, UK , Anglo-Continental School of English',
      period: 'June 2006 – July 2006',
      skills: ['English', 'Communication', 'Listening', 'Speaking', 'Reading', 'Writing'],
      contents: `
`
    },
    {
      title: 'English - Intermediate, Advanced and Master levels, Cultura Inglesa',
      period: 'June 2004 – December 2009',
      skills: ['English', 'Communication', 'Listening', 'Speaking', 'Reading', 'Writing'],
      contents: `
`
    }
  ],
  competitions: [
    {
      title: 'RoboCup Junior World Cup | Rescue, Shanghai, China',
      period: 'July 2008',
      contents: `
`
    },
    {
      title: '3rd place at RoboCup Junior Brazil Open| Rescue, Florianópolis, Brazil',
      period: 'July 2007',
      contents: `
`
    },
    {
      title: '1st place at RoboCup Junior BR Nationals | Rescue, Florianópolis, Brazil',
      period: 'July 2007',
      contents: `
`
    },
    {
      title: '1st place at RoboCup Junior ES Regionals | Rescue, Florianópolis, Brazil',
      period: 'June 2007',
      contents: `
`
    }
  ]
}
