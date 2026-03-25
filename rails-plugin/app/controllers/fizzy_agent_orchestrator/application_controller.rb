module FizzyAgentOrchestrator
  class ApplicationController < ::ApplicationController
    # Inherits Fizzy's full auth stack:
    # - AccountSlug middleware sets Current.account
    # - Authentication concern sets before_action :require_authentication
    # - Current.session= → Current.identity= → Current.user= chain
    # Engine isolation (isolate_namespace) handles routes/helpers separately.
  end
end
