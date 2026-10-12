---
layout: default
title: Home
---

<section class="hero">
  <p class="hero__prompt" aria-hidden="true"><span>~/fsoftt</span> $ dotnet run --project portfolio</p>
  <h1>Building <em>practical</em> and thoughtful software.</h1>
  <p class="hero__lead">
    I enjoy creating tools that are useful, polished, and easy to maintain — with a strong focus on .NET,
    performance, and developer experience.
  </p>
  <div class="hero__actions">
    <a class="button button--primary" href="#projects">See my projects</a>
    <a class="button button--ghost" href="#writing">Read the blog</a>
  </div>
  <dl class="hero__stats">
    <div><dt>Projects</dt><dd>{{ site.data.projects | size }}</dd></div>
    <div><dt>Posts</dt><dd>{{ site.posts | size }}</dd></div>
    <div><dt>Stack</dt><dd>.NET</dd></div>
  </dl>
</section>

<section class="projects" id="projects" aria-labelledby="projects-title">
  <div class="projects__top">
    <div class="section-heading">
      <p class="eyebrow"><span>01</span> Featured work</p>
      <h2 id="projects-title">My projects</h2>
    </div>
    <div class="slider-controls">
      <button class="slider-btn" type="button" data-slide="-1" aria-label="Previous projects">&#8249;</button>
      <button class="slider-btn" type="button" data-slide="1" aria-label="Next projects">&#8250;</button>
    </div>
  </div>

  <div class="slider">
    <div class="slider-track" tabindex="0" aria-label="Projects">
      {% for project in site.data.projects %}
        <article class="title-card" style="--accent: {{ project.accent }}; --accent-2: {{ project.accent_2 }};">
          <a class="title-card__link" href="{{ project.url }}" target="_blank" rel="noreferrer">
            <div class="title-card__poster">
              <img src="{{ project.image | relative_url }}" alt="{{ project.name }} screenshot" loading="lazy" />
              <span class="title-card__badge">{{ project.badge }}</span>
            </div>
            <div class="title-card__body">
              <h3>{{ project.name }}</h3>
              <p>{{ project.description }}</p>
              <ul class="title-card__tags">
                {% for tag in project.tags %}<li>{{ tag }}</li>{% endfor %}
              </ul>
              <ul class="title-card__highlights">
                {% for item in project.highlights %}<li>{{ item }}</li>{% endfor %}
              </ul>
              <span class="title-card__cta">Visit site <span aria-hidden="true">&rarr;</span></span>
            </div>
          </a>
        </article>
      {% endfor %}
    </div>
  </div>
</section>

<section class="contact-cta">
  <p class="eyebrow"><span>02</span> Let’s build something useful</p>
  <h2>Need a product, a system, or a thoughtful engineering partner?</h2>
  <p>I work on software products, architectural problem-solving, and practical product ideas from concept to implementation.</p>
  <a class="button button--primary" href="mailto:{{ site.email }}">Email me</a>
</section>

<section class="posts" id="writing">
  <div class="section-heading">
    <p class="eyebrow"><span>03</span> Writing</p>
    <h2>Latest posts</h2>
  </div>

  <ol class="post-list">
    {% for post in site.posts %}
      <li class="post-item">
        <a href="{{ post.url | relative_url }}">
          <span class="post-item__index">{{ forloop.index | prepend: '0' | slice: -2, 2 }}</span>
          <span class="post-item__title">{{ post.title }}</span>
          <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%b %-d, %Y" }}</time>
        </a>
      </li>
    {% endfor %}
  </ol>
</section>

<script>
  (function () {
    var track = document.querySelector('.slider-track');
    if (!track) return;
    var buttons = document.querySelectorAll('.slider-btn');

    function update() {
      var max = track.scrollWidth - track.clientWidth - 2;
      buttons[0].disabled = track.scrollLeft <= 2;
      buttons[1].disabled = track.scrollLeft >= max;
    }

    buttons.forEach(function (button) {
      button.addEventListener('click', function () {
        track.scrollBy({ left: Number(button.dataset.slide) * track.clientWidth * 0.85, behavior: 'smooth' });
      });
    });
    track.addEventListener('scroll', update, { passive: true });
    window.addEventListener('resize', update);
    update();
  })();
</script>
