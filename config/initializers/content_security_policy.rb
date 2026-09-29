# Be sure to restart your web server when you modify this file.
#
# A Content-Security-Policy is the backstop for the XSS class: every `raw` /
# `html_safe` call in this app is a place where one missed escape would otherwise be
# directly exploitable, and the policy is what limits the blast radius if one slips in.
#
# Inline <script> blocks carry a per-request nonce (see script-src below), so they are
# covered without falling back to 'unsafe-inline'. Style attributes cannot be nonced,
# and this app sets them inline throughout, so style-src still has to allow
# 'unsafe-inline' — that gap only matters once script injection is possible.
#
# External origins are the ones actually referenced by the app: jsDelivr for the
# marked/DOMPurify markdown preview, and Google Fonts. `img-src` also has to allow the
# configured CDN, because design and product images are served from there.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    policy.script_src  :self, :https, "https://cdn.jsdelivr.net"
    policy.style_src   :self, :https, :unsafe_inline, "https://fonts.googleapis.com"
    policy.connect_src :self, :https
    policy.frame_src   :self, :https
    policy.base_uri    :self
    # auth.hackclub.com has to be here even though the form posts to this app: the login
    # handoff form's response is a redirect to the provider, and form-action is enforced
    # against the navigation's destination, so with 'self' alone the browser silently
    # dropped the redirect and left the user sitting on /login.
    policy.form_action :self, "https://auth.hackclub.com"
    policy.frame_ancestors :none
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  #
  # A fresh random value per request, not the session id: the session id is only
  # assigned once something writes to the session, so `request.session.id.to_s` yields
  # an empty nonce on any request that does not (which then blocks every inline script).
  # Rails memoises the result in the rack env, so the view and the header always agree.
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]

  # Automatically add `nonce` to `javascript_tag`, `javascript_include_tag`, and
  # `stylesheet_link_tag` if the corresponding directives are specified in
  # `content_security_policy_nonce_directives`.
  config.content_security_policy_nonce_auto = true
end
