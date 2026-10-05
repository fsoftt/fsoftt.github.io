---
layout: default
title: Home
---

<section class="hero">
  <p class="eyebrow">Software engineer</p>
  <h2>Building practical and thoughtful software.</h2>
  <p>
    I enjoy creating tools that are useful, polished, and easy to maintain — with a strong focus on .NET,
    performance, and developer experience.
  </p>
</section>

<section class="projects">
  <div class="section-heading">
    <p class="eyebrow">Featured work</p>
    <h2>My projects</h2>
  </div>

  <div class="project-grid">
    <article class="project-card project-card--reader">
      <div class="project-screenshot">
        <img src="{{ '/assets/projects/piccolo-reader.svg' | relative_url }}" alt="PiccoloReader preview" />
      </div>
      <div class="project-card__content">
        <div class="project-card__header">
          <span class="project-badge">Music reader</span>
          <h3><a href="https://fsoftt.github.io/PiccoloReader/" target="_blank" rel="noreferrer">PiccoloReader</a></h3>
        </div>
        <p>Piccolo is a music reader and study companion built for musicians who want a clean, focused way to browse and read sheet music with minimal friction.</p>
        <ul class="project-tags">
          <li>Sheet music</li>
          <li>UX</li>
          <li>Reading flow</li>
        </ul>
        <ul class="project-highlights">
          <li>Focused reading experience</li>
          <li>Built for study and practice</li>
        </ul>
      </div>
    </article>

    <article class="project-card project-card--deliver">
      <div class="project-screenshot">
        <img src="{{ '/assets/projects/deliver.svg' | relative_url }}" alt="Deliver preview" />
      </div>
      <div class="project-card__content">
        <div class="project-card__header">
          <span class="project-badge">Architecture</span>
          <h3><a href="https://fsoftt.github.io/Deliver/" target="_blank" rel="noreferrer">Deliver</a></h3>
        </div>
        <p>Deliver is a portfolio project demonstrating microservices, domain-driven design, API gateways, bounded contexts, asynchronous messaging, and event-driven integration patterns in a realistic delivery workflow.</p>
        <ul class="project-tags">
          <li>Microservices</li>
          <li>DDD</li>
          <li>Event-driven</li>
        </ul>
        <ul class="project-highlights">
          <li>API gateway + bounded contexts</li>
          <li>Asynchronous workflows with events</li>
        </ul>
      </div>
    </article>

    <article class="project-card project-card--tranqui">
      <div class="project-screenshot">
        <img src="{{ '/assets/projects/tranqui.svg' | relative_url }}" alt="Tranqui preview" />
      </div>
      <div class="project-card__content">
        <div class="project-card__header">
          <span class="project-badge">Spam blocker</span>
          <h3><a href="https://fsoftt.github.io/Tranqui/" target="_blank" rel="noreferrer">Tranqui</a></h3>
        </div>
        <p>Tranqui is a privacy-focused mobile spam blocker. It identifies unwanted calls and builds a shared database of spam numbers from community reports, without storing plain phone numbers in clear text.</p>
        <ul class="project-tags">
          <li>Mobile</li>
          <li>Privacy</li>
          <li>Community data</li>
        </ul>
        <ul class="project-highlights">
          <li>Hash-based phone storage</li>
          <li>Shared spam detection network</li>
        </ul>
      </div>
    </article>

    <article class="project-card project-card--percha">
      <div class="project-screenshot">
        <img src="{{ '/assets/projects/percha.svg' | relative_url }}" alt="Percha preview" />
      </div>
      <div class="project-card__content">
        <div class="project-card__header">
          <span class="project-badge">Pattern design</span>
          <h3><a href="https://fsoftt.github.io/Percha/" target="_blank" rel="noreferrer">Percha</a></h3>
        </div>
        <p>Percha generates ready-to-cut clothing patterns from user measurements, helping turn body dimensions into printable, scale-accurate sewing patterns for garment construction.</p>
        <ul class="project-tags">
          <li>Patternmaking</li>
          <li>SVG</li>
          <li>Browser app</li>
        </ul>
        <ul class="project-highlights">
          <li>Generates sewing patterns from measurements</li>
          <li>Exports to PDF and SVG</li>
        </ul>
      </div>
    </article>
  </div>
</section>

<section class="contact-cta">
  <p class="eyebrow">Let’s build something useful</p>
  <h2>Need a product, a system, or a thoughtful engineering partner?</h2>
  <p>I work on software products, architectural problem-solving, and practical product ideas from concept to implementation.</p>
  <a class="contact-button" href="mailto:fsilva@duck.com">Email me</a>
</section>

<section class="posts">
  <div class="section-heading">
    <p class="eyebrow">Writing</p>
    <h2>Latest posts</h2>
  </div>

  <div class="post-list">
    {% for post in site.posts %}
      <article class="post-item">
        <h3><a href="{{ post.url | relative_url }}">{{ post.title }}</a></h3>
        <p><small>{{ post.date | date: "%B %-d, %Y" }}</small></p>
      </article>
    {% endfor %}
  </div>
</section>
