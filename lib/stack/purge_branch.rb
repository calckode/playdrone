class Stack::PurgeBranch < Stack::Base
  def call(env)
    repo = env[:repo]
    branch = env[:purge_branch].to_s

    repo.refs(/^refs\/(tags|heads)\/#{branch}-/).each(&:delete!)
    # garbage collection is done by PrepareFS

    @stack.call(env)
  end
end