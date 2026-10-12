const PRINCIPAL_CATEGORIES = ['Restaurante']
const SECONDARY_CATEGORIES = ['Barberia', 'Belleza']

export function getCategoryStyle(category: string): string{
    if(PRINCIPAL_CATEGORIES.includes(category)){
        return 'bg-primary/20 text-primary'
    }

    if(SECONDARY_CATEGORIES.includes(category)){
        return 'bg-secondary/20 text-secondary'
    }

    return 'bg-highlight/20 text-foreground'
}

export function getColorCategory(category: string): string{
    if(PRINCIPAL_CATEGORIES.includes(category)){
        return 'text-primary'
    }

    if(SECONDARY_CATEGORIES.includes(category)){
        return 'text-secondary'
    }

    return 'text-highlight'
}