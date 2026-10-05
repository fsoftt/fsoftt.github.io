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
      <div class="project-card__header">
        <span class="project-badge">Music reader</span>
        <h3><a href="https://fsoftt.github.io/PiccoloReader/" target="_blank" rel="noreferrer">PiccoloReader</a></h3>
      </div>
      <p>Piccolo is a music reader and study companion built for musicians who want a clean, focused way to browse and read sheet music with minimal friction.</p>
    </article>

    <article class="project-card project-card--deliver">
      <div class="project-screenshot">
        <img src="{{ '/assets/projects/deliver.svg' | relative_url }}" alt="Deliver preview" />
      </div>
      <div class="project-card__header">
        <span class="project-badge">Architecture</span>
        <h3><a href="https://fsoftt.github.io/Deliver/" target="_blank" rel="noreferrer">Deliver</a></h3>
      </div>
      <p>Deliver is a portfolio project demonstrating microservices, domain-driven design, API gateways, bounded contexts, asynchronous messaging, and event-driven integration patterns in a realistic delivery workflow.</p>
    </article>

    <article class="project-card project-card--tranqui">
      <div class="project-screenshot">
        <img src="{{ '/assets/projects/tranqui.svg' | relative_url }}" alt="Tranqui preview" />
      </div>
      <div class="project-card__header">
        <span class="project-badge">Spam blocker</span>
        <h3><a href="https://fsoftt.github.io/Tranqui/" target="_blank" rel="noreferrer">Tranqui</a></h3>
      </div>
      <p>Tranqui is a privacy-focused mobile spam blocker. It identifies unwanted calls and builds a shared database of spam numbers from community reports, without storing plain phone numbers in clear text.</p>
    </article>

    <article class="project-card project-card--percha">
      <div class="project-screenshot">
        <img src="{{ '/assets/projects/percha.svg' | relative_url }}" alt="Percha preview" />
      </div>
      <div class="project-card__header">
        <span class="project-badge">Pattern design</span>
        <h3><a href="https://fsoftt.github.io/Percha/" target="_blank" rel="noreferrer">Percha</a></h3>
      </div>
      <p>Percha generates ready-to-cut clothing patterns from user measurements, helping turn body dimensions into printable, scale-accurate sewing patterns for garment construction.</p>
    </article>
  </div>
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
