
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const { data: { user } } = await supabaseClient.auth.getUser()

    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    // 1. Fetch User Profile
    const { data: profile, error: profileError } = await supabaseClient
      .from('job_seeker_profiles')
      .select('*')
      .eq('user_id', user.id)
      .single()

    if (profileError || !profile) {
      // If no seeker profile, maybe return empty or handle error
      return new Response(JSON.stringify({ error: 'Profile not found' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404,
      })
    }

    // 2. Fetch Active Jobs (Optimization: could constrain by lat/lng if DB supports, but here we fetch active and filter in memory for now as Dataset is likely small)
    // Fetching fields needed for display and scoring
    const { data: jobs, error: jobsError } = await supabaseClient
      .from('job_posts')
      .select('*')
      .eq('is_active', true)
      .eq('admin_disabled', false) 
      .limit(100) // Consider limit for performance if many jobs

    if (jobsError) {
      throw jobsError
    }

    // 3. Score Jobs
    const userLat = profile.latitude
    const userLng = profile.longitude
    const userSkills: string[] = (profile.skills || []).map((s: string) => s.toLowerCase())
    const preferredDist = profile.preferred_distance || 50

    const scoredJobs = jobs.map((job) => {
      let score = 0
      
      // Location Score
      let distance = 0
      if (userLat != null && userLng != null && job.latitude != null && job.longitude != null) {
        distance = getDistanceFromLatLonInKm(userLat, userLng, job.latitude, job.longitude)
        
        if (distance <= 5) {
            score += 15
        } else if (distance <= 20) {
            score += 10
        } else if (distance <= preferredDist) {
            score += 5
        }
        // If strict filtering is needed:
        // if (distance > preferredDist * 2) score = -100; // Penalize far jobs
      }

      // Skills Score
      const jobSkills: string[] = (job.skills || []).map((s: string) => s.toLowerCase())
      const matchingSkills = jobSkills.filter(skill => userSkills.includes(skill))
      score += matchingSkills.length * 5

      // Work Mode Score
      // Assuming 'onsite', 'remote', 'hybrid'. If user profile has preference we can match.
      // Current profile schema might not have work_mode preference explicitly, checking plan.
      // If job is remote, maybe give a small boost as it applies to everyone?
      if (job.work_mode === 'remote') {
        score += 5
      }
      // If we had user preference:
      // if (profile.preferred_work_mode === job.work_mode) score += 5

      return { ...job, score, distance_km: distance }
    })

    // 4. Sort and Return
    // Filter out 0 score? Or just sort. Let's just sort for now.
    scoredJobs.sort((a, b) => b.score - a.score)

    // Take top 20
    const recommended = scoredJobs.slice(0, 20)

    return new Response(JSON.stringify(recommended), {
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

// Helper: Haversine Formula
function getDistanceFromLatLonInKm(lat1: number, lon1: number, lat2: number, lon2: number) {
  var R = 6371; // Radius of the earth in km
  var dLat = deg2rad(lat2-lat1);  // deg2rad below
  var dLon = deg2rad(lon2-lon1); 
  var a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * 
    Math.sin(dLon/2) * Math.sin(dLon/2)
    ; 
  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
  var d = R * c; // Distance in km
  return d;
}

function deg2rad(deg: number) {
  return deg * (Math.PI/180)
}
