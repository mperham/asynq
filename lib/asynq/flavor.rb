module Asynq
  class Flavor
    def name
      "aq"
    end

    def to_j(args)
      [Base64.urlsafe_encode64(::Marshal.dump(args))]
    end

    def from_j(arr)
      ::Marshal.load(Base64.urlsafe_decode64(arr.first))
    end
  end
end
