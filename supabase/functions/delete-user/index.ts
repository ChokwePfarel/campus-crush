import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS for browser requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Initialize Supabase with the SERVICE_ROLE_KEY (provided by Supabase environment)
    // This key has bypass-RLS permissions to delete users.
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 2. Get the userId from the request body
    const { userId } = await req.json()

    if (!userId) throw new Error('User ID is required')

    // 3. CLEANUP: Delete files from Storage (bucket: user-images)
    const { data: images } = await supabase
      .from('user_images')
      .select('path')
      .eq('user_id', userId)

    if (images && images.length > 0) {
      const paths = images.map((img) => img.path)
      await supabase.storage.from('user-images').remove(paths)
    }

    // 4. CLEANUP: Delete Database Records
    // (If you haven't set up ON DELETE CASCADE in SQL)
    await supabase.from('user_images').delete().eq('user_id', userId)
    await supabase.from('posts').delete().eq('user_id', userId)
    await supabase.from('profiles').delete().eq('id', userId)

    // 5. AUTH: Delete the user from Supabase Auth
    const { error: authError } = await supabase.auth.admin.deleteUser(userId)
    if (authError) throw authError

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
