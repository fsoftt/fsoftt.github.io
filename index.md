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
        <span class="project-badge">Reader</span>
        <h3><a href="https://github.com/fsoftt/PiccoloReader" target="_blank" rel="noreferrer">PiccoloReader</a></h3>
      </div>
      <p>A lightweight reading experience focused on clarity, speed, and distraction-free browsing.</p>
    </article>

    <article class="project-card project-card--deliver">
      <div class="project-screenshot">
        <img src="{{ '/assets/projects/deliver.svg' | relative_url }}" alt="Deliver preview" />
      </div>
      <div class="project-card__header">
        <span class="project-badge">Delivery</span>
        <h3><a href="https://github.com/fsoftt/Deliver" target="_blank" rel="noreferrer">Deliver</a></h3>
      </div>
      <p>A practical app concept centered on organizing deliveries and streamlining everyday workflows.</p>
    </article>

    <article class="project-card project-card--tranqui">
      <div class="project-screenshot">
        <img src="{{ '/assets/projects/tranqui.svg' | relative_url }}" alt="Tranqui preview" />
      </div>
      <div class="project-card__header">
        <span class="project-badge">Wellbeing</span>
        <h3><a href="https://github.com/fsoftt/Tranqui" target="_blank" rel="noreferrer">Tranqui</a></h3>
      </div>
      <p>A calm, user-friendly solution designed to support routines, focus, and a healthier pace of life.</p>
    </article>

    <article class="project-card project-card--percha">
      <div class="project-screenshot">
        <img src="{{ '/assets/projects/percha.svg' | relative_url }}" alt="Percha preview" />
      </div>
      <div class="project-card__header">
        <span class="project-badge">Commerce</span>
        <h3><a href="https://github.com/fsoftt/Percha" target="_blank" rel="noreferrer">Percha</a></h3>
      </div>
      <p>A product-driven project exploring practical commerce flows and a cleaner user experience.</p>
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
