module HasPublicAuthor
  def public_author
    self.author.try(:public_activity?) ? self.author : nil
  end
end
