const PRINCIPAL_CATEGORIES = ['restaurante']
const SECONDARY_CATEGORIES = ['barberia', 'belleza']

export function getCategoryStyle(category: string): string{
    if(PRINCIPAL_CATEGORIES.includes(category)){
        return 'bg-primary/20 text-primary'
    }

    if(SECONDARY_CATEGORIES.includes(category)){
        return 'bg-secondary/20 text-secondary'
    }

    return 'bg-highlight/20 text-foreground'
}