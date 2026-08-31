---
layout: default
title: Home
---

<section>
  <h2>Latest posts</h2>

  {% for post in site.posts %}
    <article>
      <h3><a href="{{ post.url | relative_url }}">{{ post.title }}</a></h3>
      <p><small>{{ post.date | date: "%B %-d, %Y" }}</small></p>
      {% if post.excerpt != empty %}
        <p>{{ post.excerpt | strip_html | truncatewords: 40 }}</p>
      {% endif %}
    </article>
  {% endfor %}
</section>
