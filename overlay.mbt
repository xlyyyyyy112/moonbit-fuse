///|
pub fn FuseOverlay::from_patch(
  base : VerifiedFuseFilter,
  patch : FusePatch,
) -> Result[FuseOverlay, FuseError] {
  match validate_patch(patch) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let additions = match patch.additions.length() {
    0 => None
    _ =>
      match VerifiedFuseFilter::build(patch.additions) {
        Ok(filter) => Some(filter)
        Err(error) => return Err(error)
      }
  }
  let removals = match patch.removals.length() {
    0 => None
    _ =>
      match VerifiedFuseFilter::build(patch.removals) {
        Ok(filter) => Some(filter)
        Err(error) => return Err(error)
      }
  }
  Ok({ base, additions, removals })
}

///|
pub fn FuseOverlay::contains_exact(self : FuseOverlay, hash : Int) -> Bool {
  if hash < 0 {
    return false
  }
  match self.removals {
    Some(removals) if removals.contains_exact(hash) => return false
    _ => ()
  }
  match self.additions {
    Some(additions) if additions.contains_exact(hash) => return true
    _ => self.base.contains_exact(hash)
  }
}

///|
pub fn FuseOverlay::may_contain(self : FuseOverlay, hash : Int) -> Bool {
  if hash < 0 {
    return false
  }
  if self.base.may_contain(hash) {
    return true
  }
  match self.additions {
    Some(additions) => additions.may_contain(hash)
    None => false
  }
}

///|
pub fn FuseOverlay::stats(self : FuseOverlay) -> OverlayStats {
  let addition_count = match self.additions {
    Some(filter) => filter.len()
    None => 0
  }
  let removal_count = match self.removals {
    Some(filter) => filter.len()
    None => 0
  }
  { base_key_count: self.base.len(), addition_count, removal_count }
}

///|
pub fn FuseOverlay::materialize(
  self : FuseOverlay,
) -> Result[VerifiedFuseFilter, FuseError] {
  let additions = match self.additions {
    Some(filter) => filter.hashes()
    None => []
  }
  let removals = match self.removals {
    Some(filter) => filter.hashes()
    None => []
  }
  self.base.apply_patch({ additions, removals })
}

///|
pub fn FuseOverlay::validate(self : FuseOverlay) -> Bool {
  if !self.base.validate() {
    return false
  }
  match self.additions {
    Some(filter) if !filter.validate() => return false
    _ => ()
  }
  match self.removals {
    Some(filter) if !filter.validate() => return false
    _ => ()
  }
  match (self.additions, self.removals) {
    (Some(additions), Some(removals)) =>
      for hash in additions.hashes() {
        if removals.contains_exact(hash) {
          return false
        }
      }
    _ => ()
  }
  true
}

///|
fn validate_patch(patch : FusePatch) -> Result[Unit, FuseError] {
  let additions = patch.additions.copy()
  additions.sort()
  let removals = patch.removals.copy()
  removals.sort()
  for index in 0..<additions.length() {
    if additions[index] < 0 {
      return Err(NegativeHash(additions[index]))
    }
    if index > 0 && additions[index - 1] == additions[index] {
      return Err(DuplicateHash(additions[index]))
    }
  }
  for index in 0..<removals.length() {
    if removals[index] < 0 {
      return Err(NegativeHash(removals[index]))
    }
    if index > 0 && removals[index - 1] == removals[index] {
      return Err(DuplicateHash(removals[index]))
    }
    if sorted_contains(additions, removals[index]) {
      return Err(DuplicateHash(removals[index]))
    }
  }
  Ok(())
}
