{ youtube: "youtube", frame_io: "adobe" }.each do |task_name, provider|
  namespace task_name do
    desc "Émettre un code de gestion #{task_name} valable quinze minutes pour le propriétaire"
    task inviter: :environment do
      puts OwnerInvitation.issue!(provider: provider)
    end
  end
end
