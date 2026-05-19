Istio ≤ 1.23.x: istioctl profile list works.

Istio ≥ 1.24.x: the entire istioctl profile subcommand tree is gone.

istioctl profile dump demo > demo-profile.yaml

istioctl profile dump default > default-profile.yaml

istioctl profile dump empty > empty-profile.yaml

istioctl profile dump minimal > minimal-profile.yaml

istioctl profile dump ambient > ambient-profile.yaml

$ istioctl install -f default-profile.yaml --dry-run

        |\          
        | \         
        |  \        
        |   \       
      /||    \      
     / ||     \     
    /  ||      \    
   /   ||       \   
  /    ||        \  
 /     ||         \ 
/______||__________\
____________________
  \__       _____/  
     \_____/        

✔ Istio core installed ⛵️                                                                                                                                              
✔ Istiod installed 🧠                                                                                                                                                  
✔ Ingress gateways installed 🛬                                                                                                                                        
✔ Installation complete        
